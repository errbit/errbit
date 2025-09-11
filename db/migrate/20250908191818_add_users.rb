# frozen_string_literal: true

class AddUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_users do |t|
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

      # ### Token_authenticatable
      # field :authentication_token, type: String

      # field :github_login
      # field :github_oauth_token
      # field :google_uid
      # field :name
      # field :admin, type: Boolean, default: false
      # field :per_page, type: Integer, default: PER_PAGE
      # field :time_zone, default: "UTC"

      t.timestamps null: false
    end

    add_index :errbit_users, :email, unique: true
    add_index :errbit_users, :reset_password_token, unique: true
  end
end
