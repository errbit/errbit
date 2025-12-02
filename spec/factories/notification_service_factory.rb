# frozen_string_literal: true

FactoryBot.define do
  factory :notification_service do
    app

    sequence(:room_id) { |n| "word#{n}" }

    sequence(:api_token) { |n| "word#{n}" }

    sequence(:subdomain) { |n| "word#{n}" }
  end

  factory :gtalk_notification_service, parent: :notification_service, class: "NotificationServices::GtalkService" do
    sequence(:user_id) { |n| "word#{n}" }

    sequence(:service_url) { |n| "word#{n}" }

    sequence(:service) { |n| "word#{n}" }
  end

  factory :slack_notification_service, parent: :notification_service, class: "NotificationServices::SlackService" do
    sequence(:service_url) { |n| "word#{n}" }

    sequence(:room_id) { |i| "#room-#{i}" }
  end

  factory :campfire_notification_service, parent: :notification_service, class: "NotificationServices::CampfireService"

  factory :hoiio_notification_service, parent: :notification_service, class: "NotificationServices::HoiioService"

  factory :hubot_notification_service, parent: :notification_service, class: "NotificationServices::HubotService"

  factory :pushover_notification_service, parent: :notification_service, class: "NotificationServices::PushoverService"

  factory :webhook_notification_service, parent: :notification_service, class: "NotificationServices::WebhookService"
end
