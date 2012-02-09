# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::Milestones do

  before do
    @client = Octokit::Client.new(:login => 'sferik')
  end

  describe ".list_milestones" do

    it "should list milestones belonging to repository" do
      stub_get("https://api.github.com/repos/pengwynn/octokit/milestones").
        to_return(:status => 200, :body => fixture('v3/milestones.json'))
      milestones = @client.list_milestones("pengwynn/octokit")
      milestones.first.description.should == "Add support for API v3"
    end

  end

  describe ".milestone" do

    it "should get a single milestone belonging to repository" do
      stub_get("https://api.github.com/repos/pengwynn/octokit/milestones/1").
        to_return(:status => 200, :body => fixture('v3/milestone.json'))
      milestones = @client.milestone("pengwynn/octokit", 1)
      milestones.description.should == "Add support for API v3"
    end

  end

  describe ".create_milestone" do

    it "should create a single milestone" do
      stub_post("https://api.github.com/repos/pengwynn/octokit/milestones").
        with(:body => '{"title":"0.7.0"}', :headers => {'Content-Type'=>'application/json'}).
        to_return(:status => 201, :body => fixture('v3/milestone.json'))
      milestone = @client.create_milestone("pengwynn/octokit", "0.7.0")
      milestone.title.should == "0.7.0"
    end

  end

  describe ".update_milestone" do

    it "should update a milestone" do
      stub_post("https://api.github.com/repos/pengwynn/octokit/milestones/1").
        with(:body => "{\"description\":\"Add support for API v3\"}", :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => fixture('v3/milestone.json'))
      milestone = @client.update_milestone("pengwynn/octokit", 1, {:description => "Add support for API v3"})
      milestone.description.should == "Add support for API v3"
    end

  end

  describe ".delete_milestone" do

    it "should delete a milestone from a repository" do
      stub_delete("https://api.github.com/repos/pengwynn/octokit/milestones/2").
        to_return(:status => 204, :body => "", :headers => {})
      response = @client.delete_milestone("pengwynn/octokit", 2)
      response.status.should == 204
    end

  end

end
