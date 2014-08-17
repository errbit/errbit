require 'spec_helper'

describe NotificationService::CampfireService do
  it "it should send a notification to campfire for a problem" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :campfire_notification_service, :app => notice.app
    problem = notice.problem

    #campy stubbing
    campy = double('CampfireService')
    Campy::Room.stub(:new).and_return(campy)
    campy.stub(:speak) { true }

    #assert
    expect(campy).to receive(:speak)

    notification_service.create_notification(problem)
  end

  it 'should send a notice to campfire for a deploy' do
    service = Fabricate(:campfire_notification_service)
    deploy = Fabricate(:deploy)


    campy = double('CampfireService')
    Campy::Room.stub(:new).and_return(campy)
    campy.stub(:speak) { true }

    expect(campy).to receive(:speak)

    service.create_notification(deploy)
  end
end

