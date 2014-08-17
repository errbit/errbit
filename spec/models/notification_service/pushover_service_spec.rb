require 'spec_helper'

describe NotificationService::PushoverService do
  let(:service) { Fabricate(:pushover_notification_service) }
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:deploy) { Fabricate(:deploy) }


  it "it should send a notification to Pushover for a problem" do
    notification = double('PushoverService')
    Rushover::Client.stub(:new).and_return(notification)
    notification.stub(:notify) { true }

    #assert
    expect(notification).to receive(:notify)

    service.create_notification(problem)
  end

  it "it should send a notification to Pushover for a deploy" do
    notification = double('PushoverService')
    Rushover::Client.stub(:new).and_return(notification)
    notification.stub(:notify) { true }

    #assert
    expect(notification).to receive(:notify)

    service.create_notification(deploy)
  end

end
