Fabricator(:notification_service) do
  room_id { sequence :word }
  api_token { sequence :word }
  subdomain { sequence :word }
end

Fabricator :campfire_notification_service, :from => :notification_service, :class_name => "NotificationService::CampfireService" do
  room_id '123456'
  api_token 'ertj3qh4895oqhfiugs4g74p5w96'
  subdomain 'waffles'
end

