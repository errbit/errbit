require 'spec_helper'

describe PivotalLabsTracker do
  it "should create an issue on Pivotal Tracker with err params, and set issue link for err" do
    notice = Factory :notice
    tracker = Factory :pivotal_labs_tracker, :app => notice.err.app, :project_id => 10
    err = notice.err

    story_id = 5
    @issue_link = "https://www.pivotaltracker.com/story/show/#{story_id}"
    project_body = "<project><id>#{tracker.project_id}</id><name>TestProject</name></project>"
    stub_request(:get, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}").
                 to_return(:status => 200, :headers => {'Location' => @issue_link}, :body => project_body )
    story_body = "<story><name>Test Story</name><id>#{story_id}</id></story>"
    stub_request(:post, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}/stories").
                 to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => story_body )

    err.app.issue_tracker.create_issue(err)
    err.reload

    requested = have_requested(:post, "https://www.pivotaltracker.com/services/v3/projects/#{tracker.project_id}/stories")
    WebMock.should requested.with(:headers => {'X-Trackertoken' => tracker.api_token})
    WebMock.should requested.with(:body => /See this exception on Errbit/)
    WebMock.should requested.with(:body => /<name>\[#{ err.environment }\]\[#{err.where}\] #{err.message.to_s.truncate(100)}<\/name>/)
    WebMock.should requested.with(:body => /<description>.+<\/description>/m)

    err.issue_link.should == @issue_link
  end
end

