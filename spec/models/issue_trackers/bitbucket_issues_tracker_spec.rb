require 'spec_helper'

describe IssueTrackers::BitbucketIssuesTracker do
  it "should create an issue on BitBucket Issues with problem params, and set issue link for problem" do
    repo = "test_user/test_repo"
    notice = Fabricate :notice
    notice.app.bitbucket_repo = repo
    tracker = Fabricate :bitbucket_issues_tracker, :app => notice.app
    problem = notice.problem

    number = 123
    @issue_link = "https://bitbucket.org/#{repo}/issue/#{number}/"
    body = <<EOF
{
    "status": "new",
    "priority": "critical",
    "title": "[production][foo#bar] FooError: Too Much Bar",
    "comment_count": 0,
    "content": "This is the content",
    "created_on": "2012-07-29 04:35:38",
    "local_id": 123,
    "follower_count": 0,
    "utc_created_on": "2012-07-29 02:35:38+00:00",
    "resource_uri": "/1.0/repositories/test_user/test_repo/issue/123/",
    "is_spam": false
}
EOF

    stub_request(:post, "https://#{tracker.api_token}:#{tracker.project_id}@bitbucket.org/api/1.0/repositories/test_user/test_repo/issues/").to_return(:status => 200, :headers => {}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "https://#{tracker.api_token}:#{tracker.project_id}@bitbucket.org/api/1.0/repositories/test_user/test_repo/issues/")
    WebMock.should requested.with(:title => /[production][foo#bar] FooError: Too Much Bar/)
    WebMock.should requested.with(:content => /See this exception on Errbit/)

    problem.issue_link.should == @issue_link
  end
end
