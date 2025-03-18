# frozen_string_literal: true

require "rails_helper"

RSpec.describe Issue, type: :model do
  subject(:issue) { Issue.new(problem: problem, user: user, body: body) }

  let(:problem) { notice.problem }
  let(:notice) { Fabricate(:notice) }
  let(:user) { Fabricate(:admin) }
  let(:issue_tracker) do
    Fabricate(:issue_tracker).tap do |t|
      t.instance_variable_set(:@tracker, ErrbitPlugin::MockIssueTracker.new(t.options))
    end
  end
  let(:errors) { issue.errors[:base] }

  context "when app has no issue tracker" do
    let(:body) { "barrr" }

    context "#save" do
      it "returns false" do
        expect(issue.save).to be false
      end

      it "returns an error" do
        issue.save
        expect(errors).to include("This app has no issue tracker")
      end
    end
  end

  context "when has no body" do
    let(:body) { nil }

    context "#save" do
      it "returns false" do
        expect(issue.save).to be false
      end

      it "returns an error" do
        issue.save
        expect(errors).to include("The issue has no body")
      end
    end
  end

  context "when app has a issue tracker" do
    let(:body) { "barrr" }

    before do
      problem.app.issue_tracker = issue_tracker
    end

    context "#render_body_args" do
      it "returns custom args if they exist" do
        allow(issue.tracker).to receive(:render_body_args).and_return(
          ["my", {custom: "args"}]
        )
        expect(issue.render_body_args).to eq ["my", {custom: "args"}]
      end

      it "returns default args if none exist" do
        expect(issue.render_body_args).to eq [
          "issue_trackers/issue", formats: [:md]
        ]
      end
    end

    context "#title" do
      it "returns custom title if it exists" do
        allow(issue.tracker).to receive(:title).and_return("kustomtitle")
        expect(issue.title).to eq("kustomtitle")
      end

      it "returns default title when tracker has none" do
        expect(issue.title).to include(problem.message.to_s)
      end
    end

    context "#save" do
      context "when issue tracker has errors" do
        before do
          issue_tracker.tracker.options.clear
        end

        it("returns false") { expect(issue.save).to be false }
        it "adds the errors" do
          issue.save
          expect(errors).to include("foo is required")
          expect(errors).to include("bar is required")
        end
      end

      it "creates the issue" do
        issue.save
        expect(issue_tracker.tracker.output.count).to be 1
      end

      it "returns true" do
        expect(issue.save).to be true
      end

      it "sends the title" do
        issue.save
        saved_issue = issue_tracker.tracker.output.first
        expect(saved_issue.first).to eq issue.title
      end

      it "sends the body" do
        issue.save
        saved_issue = issue_tracker.tracker.output.first
        expect(saved_issue[1]).to be body
      end
    end
  end
end
