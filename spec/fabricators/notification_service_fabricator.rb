# frozen_string_literal: true

Fabricator :notification_service do
  app

  room_id { sequence :word }

  api_token { sequence :word }

  subdomain { sequence :word }

  notify_at_notices { sequence { |_| [0] } }
end

Fabricator :gtalk_notification_service, from: :notification_service, class_name: "NotificationServices::GtalkService" do
  user_id { sequence :word }

  service_url { sequence :word }

  service { sequence :word }
end

Fabricator :slack_notification_service, from: :notification_service, class_name: "NotificationServices::SlackService" do
  service_url { sequence :word }

  room_id { sequence(:room_id) { |i| "#room-#{i}" } }
end

Fabricator :campfire_notification_service, from: :notification_service, class_name: "NotificationServices::CampfireService"

Fabricator :hoiio_notification_service, from: :notification_service, class_name: "NotificationServices::HoiioService"

Fabricator :hubot_notification_service, from: :notification_service, class_name: "NotificationServices::HubotService"

Fabricator :pushover_notification_service, from: :notification_service, class_name: "NotificationServices::PushoverService"

Fabricator :webhook_notification_service, from: :notification_service, class_name: "NotificationServices::WebhookService"
