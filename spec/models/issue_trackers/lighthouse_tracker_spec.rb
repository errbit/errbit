require 'spec_helper'

describe IssueTrackers::LighthouseTracker do
  it "should create an issue on Lighthouse with problem params, and set issue link for problem" do
    notice = Fabricate :notice
    tracker = Fabricate :lighthouse_tracker, :app => notice.app
    problem = notice.problem

    number = 5
    @issue_link = "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets/#{number}.xml"
    body = "<ticket><number type=\"integer\">#{number}</number></ticket>"
    stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").
                 to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml")
    expect(WebMock).to requested.with(:headers => {'X-Lighthousetoken' => tracker.api_token})
    expect(WebMock).to requested.with(:body => /<tag>errbit<\/tag>/)
    expect(WebMock).to requested.with(:body => /<title>\[#{ problem.environment }\]\[#{problem.where}\] #{problem.message.to_s.truncate(100)}<\/title>/)
    expect(WebMock).to requested.with(:body => /<body>.+<\/body>/m)

    expect(problem.issue_link).to eq @issue_link.sub(/\.xml$/, '')
  end
end

