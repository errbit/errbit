require 'spec_helper'

describe NotificationService::HoiioService do
  it "it should send a notification to hoiio" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :hoiio_notification_service, :app => notice.app
    problem = notice.problem

    # hoi stubbing
    sms = double('HoiioService')
    Hoi::SMS.stub(:new).and_return(sms)
    sms.stub(:send) { true }

    #assert
    sms.should_receive(:send)

    notification_service.create_notification(problem)
  end
end

