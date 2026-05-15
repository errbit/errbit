# frozen_string_literal: true

class CreateErrbitNotificationServices < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_notification_services do |t|
      t.string :bson_id
      t.references :errbit_app, foreign_key: true, index: {unique: true}

      t.string :type
      t.string :room_id
      t.string :mentions
      t.string :user_id
      t.string :service_url
      t.string :service
      t.string :api_token
      t.string :subdomain
      t.string :sender_name
      t.text :notify_at_notices

      t.timestamps
    end

    add_index :errbit_notification_services, :bson_id, unique: true
    add_index :errbit_notification_services, :type
  end
end
