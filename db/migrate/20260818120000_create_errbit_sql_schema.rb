# frozen_string_literal: true

class CreateErrbitSqlSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_users do |t|
      t.string :bson_id
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.string :authentication_token
      t.string :name
      t.string :username
      t.boolean :admin, null: false, default: false
      t.integer :per_page, default: 30
      t.string :time_zone, default: "UTC"
      t.string :github_login
      t.string :github_oauth_token
      t.string :google_uid
      t.timestamps
    end

    add_index :errbit_users, :bson_id, unique: true
    add_index :errbit_users, :email, unique: true
    add_index :errbit_users, :authentication_token, unique: true
    add_index :errbit_users, :github_login, unique: true
    add_index :errbit_users, :reset_password_token, unique: true

    create_table :errbit_apps do |t|
      t.string :bson_id
      t.string :name
      t.string :api_key
      t.string :github_repo
      t.string :bitbucket_repo
      t.string :custom_backtrace_url_template
      t.string :asset_host
      t.string :repository_branch
      t.string :current_app_version
      t.boolean :notify_all_users, null: false, default: false
      t.boolean :notify_on_errs, null: false, default: true
      t.text :email_at_notices
      t.timestamps
    end

    add_index :errbit_apps, :bson_id, unique: true
    add_index :errbit_apps, :name, unique: true
    add_index :errbit_apps, :api_key, unique: true

    create_table :errbit_watchers do |t|
      t.string :bson_id
      t.references :errbit_app, null: false, foreign_key: true
      t.references :errbit_user, foreign_key: true
      t.string :email
      t.timestamps
    end

    add_index :errbit_watchers, :bson_id, unique: true

    create_table :errbit_site_configs do |t|
      t.string :bson_id
      t.boolean :error_class, null: false, default: true
      t.boolean :message, null: false, default: true
      t.integer :backtrace_lines, default: -1
      t.boolean :component, null: false, default: true
      t.boolean :action, null: false, default: true
      t.boolean :environment_name, null: false, default: true
      t.timestamps
    end

    add_index :errbit_site_configs, :bson_id, unique: true

    create_table :errbit_backtraces do |t|
      t.string :bson_id
      t.string :fingerprint
      t.json :lines
      t.timestamps
    end

    add_index :errbit_backtraces, :bson_id, unique: true
    add_index :errbit_backtraces, :fingerprint, unique: true

    create_table :errbit_problems do |t|
      t.string :bson_id
      t.references :errbit_app, null: false, foreign_key: true
      t.datetime :first_notice_at
      t.datetime :last_notice_at
      t.boolean :resolved, null: false, default: false
      t.datetime :resolved_at
      t.string :issue_link
      t.string :issue_type
      t.string :app_name
      t.integer :notices_count, null: false, default: 0
      t.integer :comments_count, null: false, default: 0
      t.text :message
      t.string :environment
      t.string :error_class
      t.string :where
      t.json :user_agents
      t.json :messages
      t.json :hosts
      t.timestamps
    end

    add_index :errbit_problems, :bson_id, unique: true
    add_index :errbit_problems, :app_name
    add_index :errbit_problems, :message
    add_index :errbit_problems, :first_notice_at
    add_index :errbit_problems, :last_notice_at
    add_index :errbit_problems, :resolved_at
    add_index :errbit_problems, :notices_count

    create_table :errbit_errs do |t|
      t.string :bson_id
      t.references :errbit_problem, null: false, foreign_key: true
      t.string :fingerprint
      t.timestamps
    end

    add_index :errbit_errs, :bson_id, unique: true
    add_index :errbit_errs, :fingerprint

    create_table :errbit_notices do |t|
      t.string :bson_id
      t.references :errbit_app, null: false, foreign_key: true
      t.references :errbit_err, null: false, foreign_key: true
      t.references :errbit_backtrace, null: false, foreign_key: true
      t.text :message
      t.json :server_environment
      t.json :request
      t.json :notifier
      t.json :user_attributes
      t.string :framework
      t.string :error_class
      t.timestamps
    end

    add_index :errbit_notices, :bson_id, unique: true
    add_index :errbit_notices, :created_at
    add_index :errbit_notices, [:errbit_err_id, :created_at, :id], name: "index_errbit_notices_on_err_created_id"

    create_table :errbit_comments do |t|
      t.string :bson_id
      t.references :errbit_problem, null: false, foreign_key: true
      t.references :errbit_user, null: false, foreign_key: true
      t.text :body
      t.timestamps
    end

    add_index :errbit_comments, :bson_id, unique: true

    create_table :errbit_notice_fingerprinters do |t|
      t.string :bson_id
      t.references :errbit_app, foreign_key: true, index: {unique: true}
      t.boolean :error_class, null: false, default: true
      t.boolean :message, null: false, default: true
      t.integer :backtrace_lines, null: false, default: -1
      t.boolean :component, null: false, default: true
      t.boolean :action, null: false, default: true
      t.boolean :environment_name, null: false, default: true
      t.string :source
      t.timestamps
    end

    add_index :errbit_notice_fingerprinters, :bson_id, unique: true

    create_table :errbit_issue_trackers do |t|
      t.string :bson_id
      t.references :errbit_app, foreign_key: true, index: {unique: true}
      t.string :type_tracker
      t.json :options
      t.timestamps
    end

    add_index :errbit_issue_trackers, :bson_id, unique: true

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
