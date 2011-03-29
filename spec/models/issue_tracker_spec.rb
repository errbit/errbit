# encoding: utf-8
require 'spec_helper'

describe IssueTracker do
  describe "#create_issue" do
    context "lighthouseapp tracker" do
      let(:tracker) { Factory :lighthouseapp_tracker }
      let(:err) { Factory :err }

      it "should make request to Lighthouseapp with err params" do
        stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml")
        tracker.create_issue err
        WebMock.should have_requested(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml")
      end
    end
  end
end
