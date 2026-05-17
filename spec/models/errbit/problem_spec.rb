# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Problem, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_problems table" do
    expect(described_class.table_name).to eq("errbit_problems")
  end

  context "validations" do
    it "requires an environment" do
      problem = build(:errbit_problem, environment: nil)

      expect(problem.valid?).to eq(false)
      expect(problem.errors[:environment]).to include("can't be blank")
    end

    it "requires an associated app" do
      problem = build(:errbit_problem, app: nil)

      expect(problem.valid?).to eq(false)
      expect(problem.errors[:app]).to include("must exist")
    end

    it "requires first_notice_at" do
      problem = build(:errbit_problem, first_notice_at: nil)

      expect(problem.valid?).to eq(false)
      expect(problem.errors[:first_notice_at]).to include("can't be blank")
    end

    it "requires last_notice_at" do
      problem = build(:errbit_problem, last_notice_at: nil)

      expect(problem.valid?).to eq(false)
      expect(problem.errors[:last_notice_at]).to include("can't be blank")
    end
  end

  context "defaults" do
    let(:problem) { build(:errbit_problem) }

    it "sets first_notice_at to now" do
      expect(problem.first_notice_at).to be_within(5).of(Time.zone.now)
    end

    it "sets last_notice_at to now" do
      expect(problem.last_notice_at).to be_within(5).of(Time.zone.now)
    end

    it "starts unresolved" do
      expect(problem.resolved).to eq(false)
    end

    it "starts with zero notices_count" do
      expect(problem.notices_count).to eq(0)
    end

    it "starts with zero comments_count" do
      expect(problem.comments_count).to eq(0)
    end

    it "initializes user_agents as an empty hash" do
      expect(problem.user_agents).to eq({})
    end

    it "initializes messages as an empty hash" do
      expect(problem.messages).to eq({})
    end

    it "initializes hosts as an empty hash" do
      expect(problem.hosts).to eq({})
    end
  end

  describe "before_create :cache_app_attributes" do
    it "stores the app's name" do
      app = create(:errbit_app, name: "MyApp")
      problem = create(:errbit_problem, app: app)

      expect(problem.app_name).to eq("MyApp")
    end
  end

  describe "scopes" do
    let!(:resolved_problem) { create(:errbit_problem, resolved: true) }
    let!(:unresolved_problem) { create(:errbit_problem, resolved: false) }

    describe ".resolved" do
      it "returns only resolved problems" do
        expect(described_class.resolved.to_a).to eq([resolved_problem])
      end
    end

    describe ".unresolved" do
      it "returns only unresolved problems" do
        expect(described_class.unresolved.to_a).to eq([unresolved_problem])
      end
    end

    describe ".ordered" do
      it "orders by last_notice_at desc" do
        older = create(:errbit_problem, last_notice_at: 2.days.ago)
        newer = create(:errbit_problem, last_notice_at: 1.minute.ago)

        ordered = described_class.ordered.to_a

        expect(ordered.index(newer)).to be < ordered.index(older)
      end
    end

    describe ".for_apps" do
      it "returns problems belonging to the given apps" do
        app = create(:errbit_app)
        problem = create(:errbit_problem, app: app)
        create(:errbit_problem)

        expect(described_class.for_apps([app]).to_a).to eq([problem])
      end
    end
  end

  describe ".all_else_unresolved" do
    let!(:resolved_problem) { create(:errbit_problem, resolved: true) }
    let!(:unresolved_problem) { create(:errbit_problem, resolved: false) }

    it "returns all when fetch_all is true" do
      expect(described_class.all_else_unresolved(true)).to match_array([resolved_problem, unresolved_problem])
    end

    it "returns only unresolved when fetch_all is false" do
      expect(described_class.all_else_unresolved(false).to_a).to eq([unresolved_problem])
    end
  end

  describe ".in_env" do
    it "filters by environment when given" do
      prod = create(:errbit_problem, environment: "production")
      create(:errbit_problem, environment: "staging")

      expect(described_class.in_env("production").to_a).to eq([prod])
    end

    it "returns all when env is blank" do
      create(:errbit_problem)
      create(:errbit_problem)

      expect(described_class.in_env("").count).to eq(2)
    end
  end

  describe ".filtered" do
    it "excludes problems by app name with -app:NAME filter" do
      kept = create(:errbit_problem, app: create(:errbit_app, name: "Kept"))
      create(:errbit_problem, app: create(:errbit_app, name: "Skip"))

      expect(described_class.filtered("-app:Skip").to_a).to eq([kept])
    end

    it "supports quoted app names with spaces" do
      kept = create(:errbit_problem, app: create(:errbit_app, name: "Kept"))
      create(:errbit_problem, app: create(:errbit_app, name: "My App"))

      expect(described_class.filtered("-app:'My App'").to_a).to eq([kept])
    end

    it "returns all problems when filter is blank" do
      create(:errbit_problem)
      create(:errbit_problem)

      expect(described_class.filtered(nil).count).to eq(2)
    end
  end

  describe ".ordered_by" do
    it "orders by app_name" do
      a = create(:errbit_problem, app: create(:errbit_app, name: "Aaa"))
      b = create(:errbit_problem, app: create(:errbit_app, name: "Bbb"))

      expect(described_class.ordered_by("app", :asc).to_a).to eq([a, b])
      expect(described_class.ordered_by("app", :desc).to_a).to eq([b, a])
    end

    it "orders by notices_count when sort is count" do
      low = create(:errbit_problem, notices_count: 1)
      high = create(:errbit_problem, notices_count: 99)

      expect(described_class.ordered_by("count", :desc).to_a).to eq([high, low])
    end

    it "raises for an unrecognized sort" do
      expect {
        described_class.ordered_by("nope", :asc)
      }.to raise_error(RuntimeError, /not a recognized sort/)
    end
  end

  describe "#resolve!" do
    it "marks the problem as resolved and stamps resolved_at" do
      problem = create(:errbit_problem)

      problem.resolve!

      expect(problem.resolved).to eq(true)
      expect(problem.resolved_at).to be_within(5).of(Time.zone.now)
    end
  end

  describe "#unresolve!" do
    it "marks the problem as unresolved and clears resolved_at" do
      problem = create(:errbit_problem, resolved: true, resolved_at: Time.zone.now)

      problem.unresolve!

      expect(problem.resolved).to eq(false)
      expect(problem.resolved_at).to be_nil
    end
  end

  describe "#unresolved?" do
    it "is true when resolved is false" do
      expect(build(:errbit_problem, resolved: false).unresolved?).to eq(true)
    end

    it "is false when resolved is true" do
      expect(build(:errbit_problem, resolved: true).unresolved?).to eq(false)
    end
  end

  describe "#link_text" do
    it "returns the message when present" do
      problem = build(:errbit_problem, message: "boom", error_class: "RuntimeError")

      expect(problem.link_text).to eq("boom")
    end

    it "falls back to error_class when message is blank" do
      problem = build(:errbit_problem, message: "", error_class: "RuntimeError")

      expect(problem.link_text).to eq("RuntimeError")
    end
  end

  describe "#uncache_notice" do
    let(:app) { create(:errbit_app) }
    let(:problem) { create(:errbit_problem, app: app) }
    let(:err) { create(:errbit_err, problem: problem) }
    let!(:first_notice) { Errbit::Problem.cache_notice(problem.id, build(:errbit_notice, err: err, app: app, message: "first").tap { |n| n.created_at = 2.days.ago; n.save! }) && err.notices.find_by(message: "first") }
    let!(:second_notice) { Errbit::Problem.cache_notice(problem.id, build(:errbit_notice, err: err, app: app, message: "second").tap { |n| n.created_at = 1.day.ago; n.save! }) && err.notices.find_by(message: "second") }

    it "decrements notices_count" do
      expect { problem.reload.uncache_notice(second_notice) }
        .to change { problem.reload.notices_count }.from(2).to(1)
    end

    it "refreshes the cached scalar fields from the latest remaining notice" do
      problem.reload.uncache_notice(second_notice)

      expect(problem.reload.message).to eq("second")
    end

    it "drops the message digest entry when its count hits zero" do
      digest = Digest::MD5.hexdigest("second")
      expect(problem.reload.messages).to have_key(digest)

      problem.reload.uncache_notice(second_notice)

      expect(problem.reload.messages).not_to have_key(digest)
    end
  end

  describe "#issue_type" do
    it "returns the stored value when set" do
      problem = build(:errbit_problem, issue_type: "github")

      expect(problem.issue_type).to eq("github")
    end

    it "falls back to the app's issue tracker type when unset" do
      app = create(:errbit_app)
      app.build_issue_tracker(type_tracker: "mock", options: {"foo" => "1"})
      app.issue_tracker.save!(validate: false)
      problem = create(:errbit_problem, app: app, issue_type: nil)

      allow(app.issue_tracker).to receive(:configured?).and_return(true)
      allow(problem.app).to receive(:issue_tracker_configured?).and_return(true)
      allow(problem.app).to receive(:issue_tracker).and_return(app.issue_tracker)

      expect(problem.issue_type).to eq("mock")
    end

    it "returns nil when issue_type is unset and the app has no tracker" do
      problem = create(:errbit_problem, issue_type: nil)

      expect(problem.issue_type).to be_nil
    end
  end

  describe "#grouped_notice_count_relative_percentages" do
    let(:problem) { create(:errbit_problem) }
    let(:err) { create(:errbit_err, problem: problem) }

    it "returns one entry per bucket as a percentage of the max bucket" do
      base = Time.zone.parse("2026-05-15 12:00:00")
      [base + 1.hour, base + 2.hours, base + 2.hours, base + 3.hours, base + 3.hours, base + 3.hours].each do |t|
        n = build(:errbit_notice, err: err, app: err.app)
        n.created_at = t
        n.save!
      end

      result = problem.grouped_notice_count_relative_percentages(base, "hour")

      expect(result.size).to eq(24)
      # Bucket-0 (hour 12) has 0; bucket-1 (hour 13) has 1; bucket-2 (hour 14) has 2;
      # bucket-3 (hour 15) has 3 → max 3 → percentages 0%, 33.3%, 66.6%, 100%, 0%…
      expect(result[0]).to eq(0)
      expect(result[1]).to be_within(0.01).of(100.0 / 3)
      expect(result[2]).to be_within(0.01).of(200.0 / 3)
      expect(result[3]).to be_within(0.01).of(100.0)
    end

    it "returns all zeros when there are no notices in the window" do
      result = problem.grouped_notice_count_relative_percentages(1.year.ago, "day")

      expect(result.size).to eq(14)
      expect(result.uniq).to eq([0])
    end
  end

  describe "Errbit::Notice before_destroy :problem_recache" do
    let(:app) { create(:errbit_app) }
    let(:problem) { create(:errbit_problem, app: app) }
    let(:err) { create(:errbit_err, problem: problem) }
    let!(:notice_a) do
      n = build(:errbit_notice, err: err, app: app, message: "A")
      n.created_at = 2.days.ago
      n.save!
      Errbit::Problem.cache_notice(problem.id, n)
      n
    end
    let!(:notice_b) do
      n = build(:errbit_notice, err: err, app: app, message: "B")
      n.created_at = 1.day.ago
      n.save!
      Errbit::Problem.cache_notice(problem.id, n)
      n
    end

    it "decrements the problem's notices_count when a notice is destroyed" do
      expect { notice_b.destroy }
        .to change { problem.reload.notices_count }.from(2).to(1)
    end
  end
end
