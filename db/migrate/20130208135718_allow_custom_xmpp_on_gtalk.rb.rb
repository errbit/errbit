class AllowCustomXmppOnGtalk < Mongoid::Migration
  def self.up
    App.all.each do |app|
      if app.notification_service and app.notification_service._type.include?("Gtalk")
        user_id = app.notification_service.room_id
        app.notification_service.update_attributes(:service => 'talk.google.com',
                                                   :service_url => "http://www.google.com/talk/",
                                                   :user_id => user_id,
                                                   :room_id => nil)
                                                   
      end
    end
  end

  def self.down
  end
end
