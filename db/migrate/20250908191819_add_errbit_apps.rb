# frozen_string_literal: true

class AddErrbitApps < ActiveRecord::Migration[8.0]
  def change
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
      # field :email_at_notices, type: Array, default: Errbit::Config.email_at_notices

      t.timestamps null: false
    end

    add_index :errbit_apps, :bson_id, unique: true
  end
end
