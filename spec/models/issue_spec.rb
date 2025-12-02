# frozen_string_literal: true

require "rails_helper"

RSpec.describe Issue, type: :model do
  subject { described_class.new(problem: problem, user: user, body: body) }

  let(:problem) { notice.problem }
  let(:notice) { create(:notice) }
  let(:user) { create(:user, admin: true) }
  let(:issue_tracker) do
    Fabricate(:issue_tracker).tap do |t|
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

  context "when has no body" do
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

  context "when app has a issue tracker" do
    let(:body) { "barrr" }

    before do
      problem.app.issue_tracker = issue_tracker
    end

    describe "#render_body_args" do
      it "returns custom args if they exist" do
        allow(subject.tracker).to receive(:render_body_args).and_return(
          ["my", {custom: "args"}]
        )
        expect(subject.render_body_args).to eq(["my", {custom: "args"}])
      end

      it "returns default args if none exist" do
        expect(subject.render_body_args)
          .to eq([template: "issue_trackers/markdown"])
      end
    end

    describe "#title" do
      it "returns custom title if it exists" do
        allow(subject.tracker).to receive(:title).and_return("kustomtitle")
        expect(subject.title).to eq("kustomtitle")
      end

      it "returns default title when tracker has none" do
        expect(subject.title).to include(problem.message.to_s)
      end
    end

    describe "#save" do
      context "when issue tracker has errors" do
        before do
          issue_tracker.tracker.options.clear
        end

        it "returns false" do
          expect(subject.save).to eq(false)
        end

        it "adds the errors" do
          subject.save

          expect(errors).to include("foo is required")

          expect(errors).to include("bar is required")
        end
      end

      it "creates the issue" do
        subject.save

        expect(issue_tracker.tracker.output.count).to eq(1)
      end

      it "returns true" do
        expect(subject.save).to eq(true)
      end

      it "sends the title" do
        subject.save

        saved_issue = issue_tracker.tracker.output.first

        expect(saved_issue.first).to eq(subject.title)
      end

      it "sends the body" do
        subject.save

        saved_issue = issue_tracker.tracker.output.first

        expect(saved_issue[1]).to eq(body)
      end
    end
  end
end
