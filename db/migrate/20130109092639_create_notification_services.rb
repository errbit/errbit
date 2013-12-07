class CreateNotificationServices < ActiveRecord::Migration
  def change
    create_table :notification_services do |t|
      t.integer :app_id
      t.string :room_id
      t.string :user_id
      t.string :service_url
      t.string :service
      t.string :api_token
      t.string :subdomain
      t.string :sender_name
      t.string :type
      t.text :notify_at_notices

      t.timestamps
    end

    add_index :notification_services, :app_id
  end
end
