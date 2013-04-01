
require 'spec_helper'
require "pp"

describe IssueTrackers::JiraTracker do
  describe "Data" do
    let(:klass) { IssueTrackers::JiraTracker::Data }
    let(:user) { Fabricate(:user, :email => "testTEST@test.test")}
    it "creates a nice hash without reporter" do
      klass.new("KAM").fields["fields"].should include "summary"
      klass.new("KAM").fields["fields"].should_not include "reporter"
    end

    it "creates a nice hash with reporter" do
      klass.new("KAM", user).fields["fields"].should include "reporter"
    end
    
    it "includes correct data" do
      data = klass.new("kamil", user)
      data.summary = "lalalalaala"
      data.description = "nananananan"
      data.to_json.should include "lalalalaala"
      data.to_json.should include "nananananan"
    end
    it "includes correct user" do
      klass.new("kamil", user).to_json.should include "testTEST"
    end
  end
  
  describe "User Name From Email Extractor" do
    let(:klass) { IssueTrackers::JiraTracker::UserNameFromEmailExtractor }
    it "extracts username from email" do
      klass.new("hello@test.test").extract.should == "hello"
    end
    it "extracts username from empty string" do
      klass.new("").extract.should == nil
    end
    it "extracts username from nil" do
      klass.new(nil).extract.should == nil
    end
    
    it "extracts username from invalid email address" do
      klass.new("email").extract.should == "email"
    end
    it "extracts username from invalid email address with 2x @" do
      klass.new("email@test@test").extract.should == "email"
    end
  end
  
  describe "Request" do
    let(:klass) { IssueTrackers::JiraTracker::Request}
    let(:request) { klass.new("http://test.test") }
    def stub_my_json(body)
      stub_request(:post, "http://test.test/rest/api/2/issue").with(:headers => {"Content-Type" => "application/json"}).to_return(:body => body)
    end
    
    it "parses URI correctly" do
      request.uri.to_s.should == "http://test.test/rest/api/2/issue"
    end
    
    it "removes trailing slashes" do
      klass.new("http://test.test/jira/").uri.to_s.should == "http://test.test/jira/rest/api/2/issue"
    end
    
    it "performs request" do
      stub = stub_my_json("Hello")
      request.post("data")
      stub.should have_been_requested
    end
    
    it "performs request with basic authentication" do
      stub = stub_request(:post, "http://admin:admin@test.test/rest/api/2/issue").with(:headers => {"Content-Type" => "application/json"}).to_return(:body => "nanana")
      request.login("admin", "admin").post("Hello")
      stub.should have_been_requested
    end
    
    it "posts data" do
      stub_my_json(["Hello"].to_json)
      request.post("data").body.should == ["Hello"]
    end
  end
  
  describe "JiraLinkGenerator" do
    subject { IssueTrackers::JiraTracker::JiraLinkGenerator.new("http://test.test/jira/") }
    it "generates link to post an issue" do
      subject.api_post_issue.should == "http://test.test/jira/rest/api/2/issue"
    end
    it "generates project page link" do
      subject.project_page("KAM").should == "http://test.test/jira/browse/KAM"
    end
    
    it "generates issue page link" do
      subject.issue_page("KAM-1").should == "http://test.test/jira/browse/KAM-1"
    end
  end
  
  describe "Response" do
    let(:response_instance) { response_class.new(nil, nil, nil).tap{ |response| response.stub(:body => response_body) }}
    subject { IssueTrackers::JiraTracker::Response.new(response_instance) }
    
    context "success" do
      let(:response_class) { Net::HTTPCreated }
      let(:response_body) { {"id"=>"10009", "key"=>"KAM-10", "self"=>"http://kamil-virtualbox:2990/jira/rest/api/2/issue/10009"}.to_json }
      it { should be_created }
      its(:key) { should == "KAM-10"}
    end
    
    context "failure" do
      let(:response_class) { Net::HTTPBadRequest }
      context "user doesn't exist" do
        let(:response_body) { {"errorMessages"=>[], "errors"=>{"reporter"=>"The reporter specified is not a user."}}.to_json }
        it { should be_wrong_reporter }
      end
      
      context "project doesn't exist" do
        let(:response_body) { {"errorMessages"=>[], "errors"=>{"project"=>"project is required"}}.to_json }
        it { should be_wrong_project }
      end
      
      context "issue doesn't match or not set'" do
        let(:response_body) { {"errorMessages"=>[], "errors"=>{"issuetype"=>"issue type is required"}}.to_json }
        it { should be_wrong_issue }
      end
      
      context "summary is not set" do
        let(:response_body) { {"errorMessages"=>[], "errors"=>{"summary"=>"You must specify a summary of the issue."}}.to_json }
        it { should be_missing_summary }
      end
    end
  end
  
  let(:notice) { Fabricate(:notice) }
  let(:app) { notice.app }
  let(:tracker) { Fabricate :jira_tracker, :app => app }
  let(:problem) { notice.problem }
  describe "#url" do
    it "returns jira project url" do
      tracker.url.should == "https://jira.test.test/browse/KAM"
    end
  end
  describe "#create_issue" do
    it "validates presence of parameters" do
      expect { Fabricate :jira_tracker, :app => app, :username => nil }.to raise_exception
    end
    it "creates and issue from problem" do
      stub = stub_request(:post, "http://admin:test_pass@jira.test.test:443/rest/api/2/issue").to_return(:status => 201)
      tracker.create_issue(problem)
      stub.should have_been_requested
    end
    
    it "sets issue url to problem" do
      stub = stub_request(:post, "http://admin:test_pass@jira.test.test:443/rest/api/2/issue").to_return(:body => {"id"=>"10009", "key"=>"KAM-10", "self"=>"http://kamil-virtualbox:2990/jira/rest/api/2/issue/10009"}.to_json,:status => 201)
      tracker.create_issue(problem)
      problem.reload.issue_link.should == "https://jira.test.test/browse/KAM-10"
      problem.issue_type.should == "jira"
    end
  end 
end
