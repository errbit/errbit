Fabricator :notification_service  do
  app
  room_id "ROOM"
  api_token "api-token"
  subdomain "example"
  notify_at_notices { sequence { |a| [0]} }
end

Fabricator :gtalk_notification_service, from: :notification_service, class_name: "NotificationServices::GtalkService" do
  user_id "johnsoda"
  service_url "google.com/api"
  service "google-service"
end

%w(campfire flowdock hipchat hoiio hubot pushover webhook).each do |t|
  Fabricator "#{t}_notification_service".to_sym, from: :notification_service, class_name: "NotificationServices::#{t.camelcase}Service"
end
