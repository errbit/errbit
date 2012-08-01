require 'spec_helper'

describe IssueTrackers::CampfireTracker do
  it "should post the error to campfire and display the error" do
    # setup fabrications
    notice = Fabricate :notice
    tracker = Fabricate :campfire_tracker

    # stub out campy methods
    Campy::Room.stub(:new).and_return(tracker)
    tracker.stub(:paste) { true }

    # make sure campy received a message to send to campfire
    tracker.should_receive(:paste)

    # create the issue
    tracker.create_issue(notice.problem)
  end
end

