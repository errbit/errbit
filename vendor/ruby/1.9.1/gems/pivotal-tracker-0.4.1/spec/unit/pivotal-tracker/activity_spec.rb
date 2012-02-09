require 'spec_helper'

describe PivotalTracker::Activity do

  context "without a specified project" do
    it "should return an array of activities" do
      PivotalTracker::Activity.all.should be_a(Array)
      PivotalTracker::Activity.all.first.should be_a(PivotalTracker::Activity)
    end
  end

  context "with a specified project" do
    before do
      @project = PivotalTracker::Project.find(PROJECT_ID)
    end

    it "should return an array of activities" do
      @project.activities.all.should be_a(Array)
      @project.activities.all.first.should be_a(PivotalTracker::Activity)
    end
  end

  context "with a specified occurred since date filter" do
    it "should correctly url encode the occurred since date filter in the API call" do
      PivotalTracker::Client.stub!(:connection).and_return connection = double("Client Connection")
      connection.should_receive(:[]).with("/activities?limit=100&occurred_since_date=2010/07/29%2019:13:00%20UTC")
        .and_return double("Connection", :get => '<blah></blah>')
      PivotalTracker::Activity.all nil, :limit => 100, :occurred_since_date => DateTime.parse("2010/7/29 19:13:00 UTC")
    end
  end

end
