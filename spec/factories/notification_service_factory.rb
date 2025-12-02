# frozen_string_literal: true

FactoryBot.define do
  factory :notification_service do
    app

    sequence(:room_id) { |n| "word#{n}" }

    sequence(:api_token) { |n| "word#{n}" }

    sequence(:subdomain) { |n| "word#{n}" }
  end

  factory :gtalk_notification_service, parent: :notification_service, class: "NotificationServices::GtalkService" do
  end

  factory :slack_notification_service, parent: :notification_service, class: "NotificationServices::SlackService" do
  end

  factory :campfire_notification_service, parent: :notification_service, class: "NotificationServices::CampfireService"

  factory :hoiio_notification_service, parent: :notification_service, class: "NotificationServices::HoiioService"

  factory :hubot_notification_service, parent: :notification_service, class: "NotificationServices::HubotService"

  factory :pushover_notification_service, parent: :notification_service, class: "NotificationServices::PushoverService"

  factory :webhook_notification_service, parent: :notification_service, class: "NotificationServices::WebhookService"
end

# Fabricator :notification_service do
#   app
#
#   room_id { sequence :word }
#
#   api_token { sequence :word }
#
#   subdomain { sequence :word }
#
#   notify_at_notices { sequence { |_| [0] } }
# end
#
# Fabricator :gtalk_notification_service, from: :notification_service, class_name: "NotificationServices::GtalkService" do
#   user_id { sequence :word }
#
#   service_url { sequence :word }
#
#   service { sequence :word }
# end
#
# Fabricator :slack_notification_service, from: :notification_service, class_name: "NotificationServices::SlackService" do
#   service_url { sequence :word }
#
#   room_id { sequence(:room_id) { |i| "#room-#{i}" } }
# end
