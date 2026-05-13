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
end
