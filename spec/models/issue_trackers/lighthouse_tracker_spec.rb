require 'spec_helper'

describe LighthouseTracker do
  it "should create an issue on Lighthouse with err params, and set issue link for err" do
    notice = Factory :notice
    tracker = Factory :lighthouse_tracker, :app => notice.err.app
    err = notice.err

    number = 5
    @issue_link = "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets/#{number}.xml"
    body = "<ticket><number type=\"integer\">#{number}</number></ticket>"
    stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").
                 to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    err.app.issue_tracker.create_issue(err)
    err.reload

    requested = have_requested(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml")
    WebMock.should requested.with(:headers => {'X-Lighthousetoken' => tracker.api_token})
    WebMock.should requested.with(:body => /<tag>errbit<\/tag>/)
    WebMock.should requested.with(:body => /<title>\[#{ err.environment }\]\[#{err.where}\] #{err.message.to_s.truncate(100)}<\/title>/)
    WebMock.should requested.with(:body => /<body>.+<\/body>/m)

    err.issue_link.should == @issue_link.sub(/\.xml$/, '')
  end
end

