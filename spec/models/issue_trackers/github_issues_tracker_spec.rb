require 'spec_helper'

describe GithubIssuesTracker do
  it "should create an issue on Github Issues with problem params, and set issue link for problem" do
    notice = Fabricate :notice
    tracker = Fabricate :github_issues_tracker, :app => notice.app
    problem = notice.problem

    number = 5
    @issue_link = "https://github.com/#{tracker.project_id}/issues/#{number}"
    body = <<EOF
{
  "issue": {
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
}
EOF
    stub_request(:post, "https://#{tracker.username}%2Ftoken:#{tracker.api_token}@github.com/api/v2/json/issues/open/#{tracker.project_id}").
      to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "https://#{tracker.username}%2Ftoken:#{tracker.api_token}@github.com/api/v2/json/issues/open/#{tracker.project_id}")
    WebMock.should requested.with(:headers => {'Content-Type' => 'application/x-www-form-urlencoded'})
    WebMock.should requested.with(:body => /title=%5Bproduction%5D%5Bfoo%23bar%5D%20FooError%3A%20Too%20Much%20Bar/)
    WebMock.should requested.with(:body => /See%20this%20exception%20on%20Errbit/)

    problem.issue_link.should == @issue_link
  end
end

