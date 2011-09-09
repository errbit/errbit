require 'spec_helper'

describe RedmineTracker do
  it "should create an issue on Redmine with err params, and set issue link for err" do
    notice = Factory(:notice)
    tracker = Factory(:redmine_tracker, :app => notice.err.app, :project_id => 10)
    err = notice.err
    number = 5
    @issue_link = "#{tracker.account}/issues/#{number}.xml?project_id=#{tracker.project_id}"
    body = "<issue><subject>my subject</subject><id>#{number}</id></issue>"
    stub_request(:post, "#{tracker.account}/issues.xml").
                 to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    err.app.issue_tracker.create_issue(err)
    err.reload

    requested = have_requested(:post, "#{tracker.account}/issues.xml")
    WebMock.should requested.with(:headers => {'X-Redmine-API-Key' => tracker.api_token})
    WebMock.should requested.with(:body => /<project-id>#{tracker.project_id}<\/project-id>/)
    WebMock.should requested.with(:body => /<subject>\[#{ err.environment }\]\[#{err.where}\] #{err.message.to_s.truncate(100)}<\/subject>/)
    WebMock.should requested.with(:body => /<description>.+<\/description>/m)

    err.issue_link.should == @issue_link.sub(/\.xml/, '')
  end

  it "should generate a url where a file with line number can be viewed" do
    t = Factory(:redmine_tracker, :account => 'http://redmine.example.com', :project_id => "errbit")
    t.url_to_file("/example/file").should ==
      'http://redmine.example.com/projects/errbit/repository/annotate/example/file'
    t.url_to_file("/example/file", 25).should ==
      'http://redmine.example.com/projects/errbit/repository/annotate/example/file#L25'
  end

  it "should use the alt_project_id to generate a file/linenumber url, if given" do
    t = Factory(:redmine_tracker, :account => 'http://redmine.example.com',
                                  :project_id => "errbit",
                                  :alt_project_id => "actual_project")
    t.url_to_file("/example/file", 25).should ==
      'http://redmine.example.com/projects/actual_project/repository/annotate/example/file#L25'
  end
end

