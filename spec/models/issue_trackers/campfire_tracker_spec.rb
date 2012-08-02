require 'spec_helper'

describe IssueTrackers::CampfireTracker do
  it "should post the error to campfire and display the error" do
    # setup fabrications
    notice = Fabricate :notice
    tracker = Fabricate :campfire_tracker

    # stub out campy methods
    campy = mock('CampfireTracker')
    Campy::Room.stub(:new).and_return(campy)
    campy.stub(:speak) { true }

    # expectations
    campy.should_receive(:speak).once.with(/errbit|production|foo#bar/).and_return(true)

    # create the issue
    tracker.create_issue(notice.problem)
  end
end

