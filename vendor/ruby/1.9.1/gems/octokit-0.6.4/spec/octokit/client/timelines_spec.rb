# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::Users do

  describe ".timeline" do

    it "should return the public timeline" do
      client = Octokit::Client.new
      stub_get("https://github.com/timeline.json").
        to_return(:body => fixture("timeline.json"))
      events = client.timeline
      events.first.repository.name.should == "homebrew"
    end

  end

  describe ".user_timeline" do

    it "should return a user timeline" do
      client = Octokit::Client.new
      stub_get("https://github.com/sferik.json").
        to_return(:body => fixture("timeline.json"))
      events = client.user_timeline("sferik")
      events.first.repository.name.should == "homebrew"
    end

    context "when authenticated" do

      it "should return a user timeline" do
        client = Octokit::Client.new(:login => "sferik", :token => "OU812")
        stub_get("https://github.com/sferik.private.json?token=OU812").
          to_return(:body => fixture("timeline.json"))
        events = client.user_timeline("sferik")
        events.first.repository.name.should == "homebrew"
      end

    end

  end

end
