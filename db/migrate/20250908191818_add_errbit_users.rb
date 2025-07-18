# frozen_string_literal: true

class AddErrbitUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_users do |t|
      t.string :bson_id

      ## Database authenticatable
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Token_authenticatable
      t.string :authentication_token

      t.string :name
      t.string :username
      t.boolean :admin, null: false, default: false
      t.integer :per_page, default: 30
      t.string :time_zone, default: "UTC"

      t.string :github_login
      t.string :github_oauth_token
      t.string :google_uid

      t.timestamps null: false
    end

    add_index :errbit_users, :bson_id, unique: true

    add_index :errbit_users, :email, unique: true
    add_index :errbit_users, :reset_password_token, unique: true
    add_index :errbit_users, :github_login, unique: true
  end
end
