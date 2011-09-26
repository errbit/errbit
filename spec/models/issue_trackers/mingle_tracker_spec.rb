require 'spec_helper'

describe MingleTracker do
  it "should create an issue on Mingle with problem params, and set issue link for problem" do
    notice = Factory :notice
    tracker = Factory :mingle_tracker, :app => notice.app
    problem = notice.problem

    number = 5
    @issue_link = "#{tracker.account}/projects/#{tracker.project_id}/cards/#{number}.xml"
    @basic_auth = tracker.account.gsub("://", "://#{tracker.username}:#{tracker.password}@")
    body = "<card><id type=\"integer\">#{number}</id></card>"
    stub_request(:post, "#{@basic_auth}/api/v1/projects/#{tracker.project_id}/cards.xml").
                 to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "#{@basic_auth}/api/v1/projects/#{tracker.project_id}/cards.xml")
    WebMock.should requested.with(:headers => {'Content-Type' => 'application/xml'})
    WebMock.should requested.with(:body => /FooError: Too Much Bar/)
    WebMock.should requested.with(:body => /See this exception on Errbit/)
    WebMock.should requested.with(:body => /<card-type-name>Defect<\/card-type-name>/)

    problem.issue_link.should == @issue_link.sub(/\.xml$/, '')
  end
end

