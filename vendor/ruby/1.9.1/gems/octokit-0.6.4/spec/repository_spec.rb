# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Repository do
  context "when passed a string containg a slash" do
    before do
      @repository = Octokit::Repository.new("sferik/octokit")
    end

    it "should set the repository name and username" do
      @repository.name.should == "octokit"
      @repository.username.should == "sferik"
    end

    it "should respond to repo and user" do
      @repository.repo.should == "octokit"
      @repository.user.should == "sferik"
    end

    it "should render slug as string" do
      @repository.slug.should == "sferik/octokit"
      @repository.to_s.should == @repository.slug
    end

    it "should render url as string" do
      @repository.url.should == 'https://github.com/sferik/octokit'
    end

  end

  context "when passed a hash" do
    it "should set the repository name and username" do
      repository = Octokit::Repository.new({:username => 'sferik', :name => 'octokit'})
      repository.name.should == "octokit"
      repository.username.should == "sferik"
    end
  end

  context "when passed a Repo" do
    it "should set the repository name and username" do
      repository = Octokit::Repository.new(Octokit::Repository.new('sferik/octokit'))
      repository.name.should == "octokit"
      repository.username.should == "sferik"
    end
  end

  context "when given a URL" do
    it "should set the repository name and username" do
      repository = Octokit::Repository.from_url("https://github.com/sferik/octokit")
      repository.name.should == "octokit"
      repository.username.should == "sferik"
    end
  end
end
