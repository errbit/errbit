require 'spec_helper'

describe NotificationService::CampfireService do
  it "it should send a notification to campfire" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :campfire_notification_service, :app => notice.app
    problem = notice.problem

    #campy stubbing
    campy = double('CampfireService')
    Campy::Room.stub(:new).and_return(campy)
    campy.stub(:speak) { true }

    #assert
    campy.should_receive(:speak)

    notification_service.create_notification(problem)
  end
end

