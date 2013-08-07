require 'spec_helper'

describe NotificationService::PushoverService do
  it "it should send a notification to Pushover" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :pushover_notification_service, :app => notice.app
    problem = notice.problem

    # hoi stubbing
    notification = double('PushoverService')
    Rushover::Client.stub(:new).and_return(notification)
    notification.stub(:notify) { true }

    #assert
    notification.should_receive(:notify)

    notification_service.create_notification(problem)
  end
end
