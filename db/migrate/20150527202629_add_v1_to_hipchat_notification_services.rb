class AddV1ToHipchatNotificationServices < Mongoid::Migration
  def self.up
    App.all.each do |app|
      ns = app.notification_service
      if ns.is_a?(NotificationServices::HipchatService) && ns.service.blank?
        app.notification_service.update_attribute(:service, 'v1')
      end
    end
  end

  def self.down
  end
end
