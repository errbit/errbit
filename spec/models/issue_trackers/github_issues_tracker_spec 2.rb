require 'spec_helper'

describe IssueTrackers::GitlabTracker do
  it "should create an issue on Gitlab with problem params" do
    notice = Fabricate :notice
    tracker = Fabricate :gitlab_tracker, :app => notice.app
    problem = notice.problem

    number = 5
    @issue_link = "#{tracker.account}/#{tracker.project_id}/issues/#{number}/#{tracker.api_token}"
    body = <<EOF
{
  "title": "Title"
}
EOF

    stub_request(:post, "#{tracker.account}/#{tracker.project_id}/issues/#{tracker.api_token}").
      to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "#{tracker.account}/#{tracker.project_id}/issues/#{tracker.api_token}")
    WebMock.should requested.with(:body => /[production][foo#bar] FooError: Too Much Bar/)
    WebMock.should requested.with(:body => /See this exception on Errbit/)

    problem.issue_link.should == @issue_link
  end
end

