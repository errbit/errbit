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
    expect(WebMock).to requested.with(:headers => {'X-Redmine-API-Key' => tracker.api_token})
    expect(WebMock).to requested.with(:body => /<project-id>#{tracker.project_id}<\/project-id>/)
    expect(WebMock).to requested.with(:body => /<subject>\[#{ problem.environment }\]\[#{problem.where}\] #{problem.message.to_s.truncate(100)}<\/subject>/)
    expect(WebMock).to requested.with(:body => /<description>.+<\/description>/m)

    expect(problem.issue_link).to eq @issue_link.sub(/\.xml/, '')
  end

  it "should generate a url where a file with line number can be viewed" do
    t = Fabricate(:redmine_tracker, :account => 'http://redmine.example.com', :project_id => "errbit")
    expect(t.url_to_file("/example/file")).
      to eq 'http://redmine.example.com/projects/errbit/repository/revisions/master/changes/example/file'
    expect(t.url_to_file("/example/file", 25)).
      to eq 'http://redmine.example.com/projects/errbit/repository/revisions/master/changes/example/file#L25'
  end

  it "should use the alt_project_id to generate a file/linenumber url, if given" do
    t = Fabricate(:redmine_tracker, :account => 'http://redmine.example.com',
                                  :project_id => "errbit",
                                  :alt_project_id => "actual_project")
    expect(t.url_to_file("/example/file", 25)).
      to eq 'http://redmine.example.com/projects/actual_project/repository/revisions/master/changes/example/file#L25'
  end
end
