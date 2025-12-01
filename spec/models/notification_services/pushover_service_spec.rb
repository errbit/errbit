# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationServices::PushoverService, type: :model do
  it "should send a notification to Pushover" do
    notice = create(:notice)
    notification_service = Fabricate(:pushover_notification_service, app: notice.app)
    problem = notice.problem

    notification = double("PushoverService")
    allow(Rushover::Client).to receive(:new).and_return(notification)
    allow(notification).to receive(:notify).and_return(true)

    expect(notification).to receive(:notify)

    notification_service.create_notification(problem)
  end
end
