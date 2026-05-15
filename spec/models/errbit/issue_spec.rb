# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Issue, type: :model do
  subject { described_class.new(problem: problem, user: user, body: body) }

  let(:problem) { create(:errbit_problem) }
  let(:user) { create(:errbit_user, admin: true) }
  let(:issue_tracker) do
    create(:errbit_issue_tracker, app: problem.app).tap do |t|
      t.instance_variable_set(:@tracker, ErrbitPlugin::MockIssueTracker.new(t.options))
    end
  end
  let(:errors) { subject.errors[:base] }

  context "when app has no issue tracker" do
    let(:body) { "barrr" }

    describe "#save" do
      it "returns false" do
        expect(subject.save).to eq(false)
      end

      it "returns an error" do
        subject.save

        expect(errors).to include("This app has no issue tracker")
      end
    end
  end

  context "when there is no body" do
    let(:body) { nil }

    describe "#save" do
      it "returns false" do
        expect(subject.save).to eq(false)
      end

      it "returns an error" do
        subject.save

        expect(errors).to include("The issue has no body")
      end
    end
  end

  context "when app has an issue tracker" do
    let(:body) { "barrr" }

    before { issue_tracker }

    describe "#render_body_args" do
      it "returns custom args if the tracker provides them" do
        allow(subject.tracker).to receive(:render_body_args).and_return(
          ["my", {custom: "args"}]
        )

        expect(subject.render_body_args).to eq(["my", {custom: "args"}])
      end

      it "returns the default markdown template args otherwise" do
        expect(subject.render_body_args)
          .to eq([template: "issue_trackers/markdown"])
      end
    end

    describe "#title" do
      it "returns the tracker's custom title when present" do
        allow(subject.tracker).to receive(:title).and_return("kustomtitle")

        expect(subject.title).to eq("kustomtitle")
      end

      it "falls back to a default title built from the problem" do
        expect(subject.title).to include(problem.message.to_s)
      end
    end

    describe "#save" do
      context "when the tracker plugin has errors" do
        before { issue_tracker.tracker.options.clear }

        it "returns false" do
          expect(subject.save).to eq(false)
        end

        it "adds the tracker errors" do
          subject.save

          expect(errors).to include("foo is required")
          expect(errors).to include("bar is required")
        end
      end

      it "returns true" do
        expect(subject.save).to eq(true)
      end

      it "creates an issue on the tracker" do
        subject.save

        expect(issue_tracker.tracker.output.count).to eq(1)
      end

      it "passes the title to the tracker" do
        subject.save

        saved_issue = issue_tracker.tracker.output.first

        expect(saved_issue.first).to eq(subject.title)
      end

      it "passes the body to the tracker" do
        subject.save

        saved_issue = issue_tracker.tracker.output.first

        expect(saved_issue[1]).to eq(body)
      end
    end
  end
end
