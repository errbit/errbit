require 'spec_helper'

describe IssueTrackers::GitlabTracker do
  it "should create an issue on Gitlab with problem params" do
    notice = Fabricate :notice
    tracker = Fabricate :gitlab_tracker, :app => notice.app
    problem = notice.problem

    issue_id = 5
    note_id = 10
    issue_body = {:id => issue_id, :title => "[production][foo#bar] FooError: Too Much Bar", :description => "[See this exception on Errbit]"}.to_json
    note_body = {:id => note_id, :body => "Example note body"}.to_json

    stub_request(:post, "#{tracker.account}/api/v3/projects/#{tracker.project_id}/issues?private_token=#{tracker.api_token}").
      with(:body => /.+/, :headers => {'Accept'=>'application/json'}).
      to_return(:status => 200, :body => issue_body, :headers => {'Accept'=>'application/json'})

    stub_request(:post, "#{tracker.account}/api/v3/projects/#{tracker.project_id}/issues/#{issue_id}/notes?private_token=#{tracker.api_token}").
      with(:body => /.+/, :headers => {'Accept'=>'application/json'}).
      to_return(:status => 200, :body => note_body, :headers => {'Accept'=>'application/json'})

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested_issue = have_requested(:post, "#{tracker.account}/api/v3/projects/#{tracker.project_id}/issues?private_token=#{tracker.api_token}").with(:body => /.+/, :headers => {'Accept'=>'application/json'})
    requested_note = have_requested(:post, "#{tracker.account}/api/v3/projects/#{tracker.project_id}/issues/#{issue_id}/notes?private_token=#{tracker.api_token}")
    expect(WebMock).to requested_issue.with(:body => /%5Bproduction%5D%5Bfoo%23bar%5D%20FooError%3A%20Too%20Much%20Bar/)
    expect(WebMock).to requested_issue.with(:body => /See%20this%20exception%20on%20Errbit/)

  end
end

