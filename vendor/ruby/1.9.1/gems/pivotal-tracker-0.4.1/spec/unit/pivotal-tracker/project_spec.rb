require 'spec_helper'

describe PivotalTracker::Project do
  context ".all" do
    before do
      @projects = PivotalTracker::Project.all
    end

    it "should return an array of available projects" do
      @projects.should be_a(Array)
    end

    it "should be a project instance" do
      @projects.first.should be_a(PivotalTracker::Project)
    end
  end

  context ".find" do
    before do
      @project = PivotalTracker::Project.find(102622)
    end

    it "should be an instance of Project" do
      @project.should be_a(PivotalTracker::Project)
    end

    it "should have a use_https attribute" do
      @project.respond_to?(:use_https).should be_true
    end

    it "should have false for use_https" do
      @project.use_https.should be_false
    end
  end

  context ".stories" do
    before do
      @project = PivotalTracker::Project.find(102622)
    end

    it "should have a stories association" do
      @project.respond_to?(:stories).should be_true
    end
  end

  context ".memberships" do
    before do
      @project = PivotalTracker::Project.find(102622)
    end

    it "should have a memberships association" do
      @project.respond_to?(:memberships).should be_true
    end
  end
end
