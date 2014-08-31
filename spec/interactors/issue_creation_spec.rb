require 'spec_helper'

describe IssueCreation do
  subject(:issue_creation) do
    IssueCreation.new(problem, user, tracker_name, request)
  end

  let(:request) do
    double(:request,
           :host => 'github.com',
           :port => '80',
           :scheme => 'http'
          )
  end
  let(:problem) { notice.problem }
  let(:notice)  { Fabricate(:notice) }
  let(:user)    { Fabricate(:admin) }
  let(:errors)  { issue_creation.errors[:base] }
  let(:tracker_name) { nil }

  it "adds the error when issue tracker isn't configured" do
    issue_creation.execute
    expect(errors).to include("This app has no issue tracker setup.")
  end

  it 'creates an issue if issue tracker is configured' do
    problem.app.issue_tracker = Fabricate(:issue_tracker)
    issue_creation.execute
    expect(errors).to be_empty
  end

  context "with user's github" do
    let(:tracker_name) { 'user_github' }

    it "adds the error when repo isn't set up" do
      issue_creation.execute
      expect(errors).to include("This app doesn't have a GitHub repo set up.")
    end

    context 'with repo set up' do
      before do
        notice.app.update_attribute(:github_repo, 'errbit/errbit')
      end

      it "adds the error when github account isn't linked" do
        issue_creation.execute
        expect(errors).to include("You haven't linked your Github account.")
      end

      it 'creates an issue if github account is linked' do
        user.github_login       = 'admin'
        user.github_oauth_token = 'oauthtoken'
        user.save!

        ErrbitGithubPlugin::IssueTracker.should_receive(:new).and_return(
          double(:create_issue => true)
        )
        issue_creation.execute
        expect(errors).to be_empty
      end
    end
  end
end
