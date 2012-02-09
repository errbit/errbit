# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::Pulls do

  before do
    @client = Octokit::Client.new(:login => 'sferik')
  end

  describe ".create_pull_request" do

    it "should create a pull request" do
      stub_post("/api/v2/json/pulls/sferik/rails_admin").
        with(:pull => {:base => "master", :head => "pengwynn:master", :title => "Title", :body => "Body"}).
        to_return(:body => fixture("v2/pulls.json"))
      issues = @client.create_pull_request("sferik/rails_admin", "master", "pengwynn:master", "Title", "Body")
      issues.first.number.should == 251
    end

  end

  describe ".create_pull_request_for_issue" do

    it "should create a pull request and attach it to an existing issue" do
      stub_post("/api/v2/json/pulls/pengwynn/octokit").
        with(:pull => {:base => "master", :head => "pengwynn:master", :issue => "34"}).
        to_return(:body => fixture("v2/pulls.json"))
      issues = @client.create_pull_request_for_issue("pengwynn/octokit", "master", "pengwynn:master", "34")
      issues.first.number.should == 251
    end

  end

  describe ".pull_requests" do

    it "should return all pull requests" do
      stub_get("/api/v2/json/pulls/sferik/rails_admin/open").
        to_return(:body => fixture("v2/pulls.json"))
      pulls = @client.pulls("sferik/rails_admin")
      pulls.first.number.should == 251
    end

  end

  describe ".pull_request" do

    it "should return a pull request" do
      stub_get("/api/v2/json/pulls/sferik/rails_admin/251").
        to_return(:body => fixture("v2/pull.json"))
      pull = @client.pull("sferik/rails_admin", 251)
      pull.number.should == 251
    end

  end

end
