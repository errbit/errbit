require "spec_helper"

describe Issue do

  subject(:issue) { Issue.new(user: user, title: title, body: body) }

  let(:problem) { notice.problem }
  let(:notice)  { Fabricate(:notice) }
  let(:user)    { Fabricate(:admin) }

  context "when app has no issue tracker" do
    let(:title) { "Foo" }
    let(:body) { "barrr" }
    let(:errors) { issue.errors[:base] }

    context "#save" do
      it "returns false" do
        expect(issue.save).to be false
      end

      it "returns an error" do
        issue.save
        expect(errors).to include("This app has no issue tracker setup.")
      end
    end
  end

  context "when has no title" do
    let(:tracker) { Fabricate(:issue_tracker) }
    let(:body) { "barrr" }

    pending "returns an error" do
    end
  end

  context "when has no body" do
    let(:tracker) { Fabricate(:issue_tracker) }
    let(:title) { "Foo" }

    pending "returns an error" do
    end
  end

  context "when app has a issue tracker" do
    let(:issue_tracker) { Fabricate(:issue_tracker) }
    let(:title) { "Foo" }
    let(:body) { "barrr" }

    before do
      issue.issue_tracker = issue_tracker
    end

    context "#save" do

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
        expect(saved_issue.first).to be title
      end

      it "sends the body" do
        issue.save
        saved_issue = issue_tracker.tracker.output.first
        expect(saved_issue[1]).to be body
      end
    end
  end
end
