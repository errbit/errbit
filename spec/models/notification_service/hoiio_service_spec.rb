require 'spec_helper'

describe NotificationService::HoiioService do
  let(:service) { Fabricate(:hoiio_notification_service) }
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:deploy) { Fabricate(:deploy) }

  it "it should send a notification to hoiio for a problem" do
    sms = double('HoiioService')
    Hoi::SMS.stub(:new).and_return(sms)
    sms.stub(:send) { true }

    expect(sms).to receive(:send)

    service.create_notification(problem)
  end

  it "it should send a notification to hoiio for a problem" do
    sms = double('HoiioService')
    Hoi::SMS.stub(:new).and_return(sms)
    sms.stub(:send) { true }

    expect(sms).to receive(:send)

    service.create_notification(deploy)
  end

end

