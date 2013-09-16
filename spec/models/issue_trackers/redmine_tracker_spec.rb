require 'spec_helper'

describe IssueTrackers::RedmineTracker do
  it "should create an issue on Redmine with problem params, and set issue link for problem" do
    notice = Fabricate(:notice)
    tracker = Fabricate(:redmine_tracker, :app => notice.app, :project_id => 10)
    problem = notice.problem
    number = 5
    @issue_link = "#{tracker.account}/issues/#{number}.xml?project_id=#{tracker.project_id}"
    body = "<issue><subject>my subject</subject><id>#{number}</id></issue>"

    # Build base url with account URL, and username/password basic auth
    base_url = tracker.account.gsub 'http://', "http://#{tracker.username}:#{tracker.password}@"

    stub_request(:post, "#{base_url}/issues.xml").
                 to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post, "#{base_url}/issues.xml")
    WebMock.should requested.with(:headers => {'X-Redmine-API-Key' => tracker.api_token})
    WebMock.should requested.with(:body => /<project-id>#{tracker.project_id}<\/project-id>/)
    WebMock.should requested.with(:body => /<subject>\[#{ problem.environment }\]\[#{problem.where}\] #{problem.message.to_s.truncate(100)}<\/subject>/)
    WebMock.should requested.with(:body => /<description>.+<\/description>/m)

    problem.issue_link.should == @issue_link.sub(/\.xml/, '')
  end

  it "should generate a url where a file with line number can be viewed" do
    t = Fabricate(:redmine_tracker, :account => 'http://redmine.example.com', :project_id => "errbit")
    t.url_to_file("/example/file").should ==
      'http://redmine.example.com/projects/errbit/repository/revisions/master/changes/example/file'
    t.url_to_file("/example/file", 25).should ==
      'http://redmine.example.com/projects/errbit/repository/revisions/master/changes/example/file#L25'
  end

  it "should use the alt_project_id to generate a file/linenumber url, if given" do
    t = Fabricate(:redmine_tracker, :account => 'http://redmine.example.com',
                                  :project_id => "errbit",
                                  :alt_project_id => "actual_project")
    t.url_to_file("/example/file", 25).should ==
      'http://redmine.example.com/projects/actual_project/repository/revisions/master/changes/example/file#L25'
  end
end
