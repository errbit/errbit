Fabricator :notification_service do
  app
  room_id { sequence :word }
  api_token { sequence :word }
  subdomain { sequence :word }
  notify_at_notices { sequence { |_a| [0] } }
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

%w(campfire flowdock hoiio hubot pushover webhook).each do |t|
  Fabricator "#{t}_notification_service".to_sym, from: :notification_service, class_name: "NotificationServices::#{t.camelcase}Service"
end
