require 'spec_helper'

describe IssueTrackers::GithubIssuesTracker do

  let(:repo) { "test_user/test_repo" }

  let(:notice) do
    Fabricate :notice
  end

  let(:problem) do
    notice.problem
  end

  let!(:tracker) do
    notice.app.github_repo = repo
    Fabricate :github_issues_tracker, app: notice.app
  end

  let(:number) { 5 }
  let(:issue_link) { "https://github.com/#{repo}/issues/#{number}" }
  let(:body) do
    <<EOF
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
  "html_url": "#{issue_link}"
}
EOF
end

  it "should create an issue on GitHub Issues with problem params, and set issue link for problem" do
    stub_request(:post,
                 "https://#{tracker.username}:#{tracker.password}@api.github.com/repos/#{repo}/issues").
      to_return(:status => 201,
                :headers => {
        'Location' => issue_link,
        'Content-Type' => 'application/json',
      },
      :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "https://#{tracker.username}:#{tracker.password}@api.github.com/repos/#{repo}/issues")
    expect(WebMock).to requested.with(:body => /[production][foo#bar] FooError: Too Much Bar/)
    expect(WebMock).to requested.with(:body => /See this exception on Errbit/)

    expect(problem.issue_link).to eq issue_link
  end

  it "should create an issue with oauth token" do
    issue_tracker = problem.app.issue_tracker
    issue_tracker.oauth_token = 'secret_token'

    stub_request(:post, "https://api.github.com/repos/#{repo}/issues").
      to_return({
        status: 201,
        headers: {'Location' => issue_link, 'Content-Type' => 'application/json' },
        body: body })

    issue_tracker.create_issue(problem)
    requested = have_requested(:post, "https://api.github.com/repos/#{repo}/issues")
    expect(WebMock).to requested.with(headers: {'Authorization'=>'token secret_token'})
  end
end
