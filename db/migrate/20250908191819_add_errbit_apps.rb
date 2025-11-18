# frozen_string_literal: true

class AddErrbitApps < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_apps do |t|
      t.string :bson_id

      t.string :name
      # field :api_key
      t.string :github_repo
      t.string :bitbucket_repo
      # field :custom_backtrace_url_template
      # field :asset_host
      t.string :repository_branch
      # field :current_app_version
      # field :notify_all_users, type: Boolean, default: false
      # field :notify_on_errs, type: Boolean, default: true
      # field :email_at_notices, type: Array, default: Errbit::Config.email_at_notices

      t.timestamps null: false
    end

    add_index :errbit_apps, :bson_id, unique: true
  end
end
