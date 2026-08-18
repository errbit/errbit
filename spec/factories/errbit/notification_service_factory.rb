# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_notification_service, class: "Errbit::NotificationService" do
    association :app, factory: :errbit_app
    api_token { "token" }
  end

  factory :errbit_slack_service, class: "Errbit::NotificationServices::SlackService", parent: :errbit_notification_service do
    service_url { "https://hooks.slack.com/services/T/B/C" }
    room_id { "#errors" }
  end

  factory :errbit_webhook_service, class: "Errbit::NotificationServices::WebhookService", parent: :errbit_notification_service do
    api_token { "https://example.com/webhook" }
  end
end
