# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationServices::PushoverService, type: :model do
  it "should send a notification to Pushover.net" do
    notice = create(:notice)
    notification_service = create(:pushover_notification_service, app: notice.app)
    problem = notice.problem

    expect(Pushover2::Message).to receive(:new)
      .with(
        token: notification_service.subdomain,
        user: notification_service.api_token,
        message: notification_service.notification_description(problem),
        priority: 1,
        title: "Errbit Notification",
        url: "https://#{Config.main.host}/apps/#{problem.app.id}",
        url_title: "Link to error"
      ) do
      double.tap do |a|
        expect(a).to receive(:push)
      end
    end

    notification_service.create_notification(problem)
  end
end
