# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit do
  after do
    Octokit.reset
  end

  describe ".respond_to?" do
    it "should be true if method exists" do
      Octokit.respond_to?(:new, true).should be_true
    end
  end

  describe ".new" do
    it "should be a Octokit::Client" do
      Octokit.new.should be_a Octokit::Client
    end
  end

  describe ".delegate" do
    it "should delegate missing methods to Octokit::Client" do
      stub_get("https://api.github.com/repos/pengwynn/octokit/issues").
        to_return(:status => 200, :body => fixture('v3/issues.json'))
      issues = Octokit.issues('pengwynn/octokit')
      issues.last.user.login.should == 'fellix'
    end

  end
end
