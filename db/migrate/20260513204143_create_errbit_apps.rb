# frozen_string_literal: true

class CreateErrbitApps < ActiveRecord::Migration[8.1]
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
      t.text :email_at_notices

      t.timestamps
    end

    add_index :errbit_apps, :bson_id, unique: true
    add_index :errbit_apps, :name, unique: true
    add_index :errbit_apps, :api_key, unique: true
  end
end
