class AddIntervalFieldForNotifications < Mongoid::Migration
  def self.up
    App.all.each do |app|
      if app.notification_service
        app.notification_service.update_attributes(:notify_at_notices => [0])
      end
    end
  end

  def self.down
  end
end
