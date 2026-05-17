# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_notification_service, class: "Errbit::NotificationService" do
    association :app, factory: :errbit_app

    sequence(:room_id) { |n| "word#{n}" }
    sequence(:api_token) { |n| "word#{n}" }
    sequence(:subdomain) { |n| "word#{n}" }
  end

  factory :errbit_slack_notification_service, parent: :errbit_notification_service, class: "Errbit::NotificationServices::SlackService" do
    sequence(:service_url) { |n| "https://hooks.slack.com/services/word#{n}" }
    sequence(:room_id) { |n| "#room-#{n}" }
  end

  factory :errbit_campfire_notification_service, parent: :errbit_notification_service, class: "Errbit::NotificationServices::CampfireService"

  factory :errbit_hoiio_notification_service, parent: :errbit_notification_service, class: "Errbit::NotificationServices::HoiioService"

  factory :errbit_hubot_notification_service, parent: :errbit_notification_service, class: "Errbit::NotificationServices::HubotService"

  factory :errbit_pushover_notification_service, parent: :errbit_notification_service, class: "Errbit::NotificationServices::PushoverService"

  factory :errbit_webhook_notification_service, parent: :errbit_notification_service, class: "Errbit::NotificationServices::WebhookService"
end
