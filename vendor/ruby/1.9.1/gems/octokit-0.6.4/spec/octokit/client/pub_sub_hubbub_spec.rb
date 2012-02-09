# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::PubSubHubbub do
  let(:client) { Octokit::Client.new(:oauth_token => 'myfaketoken') }

  describe ".subscribe" do
    it "subscribes to pull events" do
      stub_post("https://api.github.com/hub?access_token=myfaketoken").
        with({
          :"hub.callback" => 'github://Travis?token=travistoken',
          :"hub.mode" => 'subscribe',
          :"hub.topic" => 'https://github.com/joshk/completeness-fu/events/push'
        }).
        to_return(:body => nil)

      client.subscribe("https://github.com/joshk/completeness-fu/events/push", "github://Travis?token=travistoken").should == true
    end

    it "raises an error if the topic is not recognized" do
      stub_post("https://api.github.com/hub?access_token=myfaketoken").
        with({
          :"hub.callback" => 'github://Travis?token=travistoken',
          :"hub.mode" => 'subscribe',
          :"hub.topic" => 'https://github.com/joshk/completeness-fud/events/push'
        }).
        to_return(:status => 422)

      proc {
        client.subscribe("https://github.com/joshk/completeness-fud/events/push", "github://Travis?token=travistoken")
      }.should raise_exception
    end
  end

  describe ".unsubscribe" do
    it "unsubscribes from pull events" do
      stub_post("https://api.github.com/hub?access_token=myfaketoken").
      with({
        :"hub.callback" => 'github://Travis?token=travistoken',
        :"hub.mode" => 'unsubscribe',
        :"hub.topic" => 'https://github.com/joshk/completeness-fu/events/push'
      }).
      to_return(:body => nil)

      client.unsubscribe("https://github.com/joshk/completeness-fu/events/push", "github://Travis?token=travistoken").should == true
    end
  end

end
