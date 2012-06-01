require 'spec_helper'

describe IssueTrackers::GithubIssuesTracker do
  it "should create an issue on Github Issues with problem params, and set issue link for problem" do
    notice = Fabricate :notice
    tracker = Fabricate :github_issues_tracker, :app => notice.app
    problem = notice.problem

    number = 5
    @issue_link = "https://github.com/#{tracker.project_id}/issues/#{number}"
    body = <<EOF
{
  "position": 1.0,
  "number": #{number},
  "votes": 0,
  "created_at": "2010/01/21 13:45:59 -0800",
  "comments": 0,
  "body": "Test Body",
  "title": "Test Issue",
  "user": "test_user",
  "state": "open",
  "html_url": "#{@issue_link}"
}
EOF

    stub_request(:post, "https://#{tracker.username}:#{tracker.password}@api.github.com/repos/#{tracker.project_id}/issues").
      to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "https://#{tracker.username}:#{tracker.password}@api.github.com/repos/#{tracker.project_id}/issues")
    WebMock.should requested.with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'})
    WebMock.should requested.with(:body => /[production][foo#bar] FooError: Too Much Bar/)
    WebMock.should requested.with(:body => /See this exception on Errbit/)

    problem.issue_link.should == @issue_link
  end
end

