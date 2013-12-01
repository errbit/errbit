require 'spec_helper'

describe IssueTrackers::PivotalLabsTracker do

  let(:user) { Fabricate(:user) }
  let(:notice) { Fabricate(:notice) }
  let(:tracker) { Fabricate :pivotal_labs_tracker, :app => notice.app, :project_id => 10 }
  let(:problem) { notice.problem }
  let(:story_id) { 5 }
  let(:issue_link) { "https://www.pivotaltracker.com/story/show/#{story_id}" }

  it "creates an issue on Pivotal Tracker with problem params, and set issue link for problem" do
    project_body = "<project><id>#{tracker.project_id}</id><name>TestProject</name></project>"
    stub_request(:get, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}").
                 to_return(:status => 200, :headers => {'Location' => issue_link}, :body => project_body )
    story_body = "<story><name>Test Story</name><id>#{story_id}</id></story>"
    stub_request(:post, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}/stories").
                 to_return(:status => 201, :headers => {'Location' => issue_link}, :body => story_body )

    problem.app.issue_tracker.create_issue(problem, user)
    problem.reload

    requested = have_requested(:post, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}/stories")
    expect(WebMock).to requested.with(:headers => {'X-Trackertoken' => tracker.api_token})
    expect(WebMock).to requested.with(:body => /See this exception on Errbit/)
    expect(WebMock).to requested.with(:body => /<name>\[#{ problem.environment }\]\[#{problem.where}\] #{problem.message.to_s.truncate(100)}<\/name>/)
    expect(WebMock).to requested.with(:body => /<description>.+<\/description>/m)

    expect(problem.issue_link).to eq issue_link
  end

  it "raises IssueTrackers::IssueTrackerError exception when invalid params and does not set issue link for problem" do
    project_body = "<project><id>#{tracker.project_id}</id><name>TestProject</name></project>"
    stub_request(:get, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}").
      to_return(:status => 200, :body => project_body )
    story_body = "<errors><error>Requested by can't be blank</error><error>Requested by can't be blank</error></errors>"
    stub_request(:post, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}/stories").
                 to_return(:status => 422, :body => story_body )

    expect{
            problem.app.issue_tracker.create_issue(problem, user)
          }.to raise_exception(IssueTrackers::IssueTrackerError, "Requested by can't be blank")
    expect(problem.issue_link).to be_nil
  end
end

