# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationServices::HoiioService, type: :model do
  it "it should send a notification to hoiio" do
    notice = Fabricate :notice
    notification_service = Fabricate :hoiio_notification_service, app: notice.app
    problem = notice.problem

    sms = double("HoiioService")
    allow(Hoi::SMS).to receive(:new).and_return(sms)
    allow(sms).to receive(:send).and_return(true)

    expect(sms).to receive(:send)

    notification_service.create_notification(problem)
  end
end
