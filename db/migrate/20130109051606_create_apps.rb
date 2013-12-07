class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :name
      t.string :api_key
      t.string :github_repo
      t.string :bitbucket_repo
      t.string :asset_host
      t.string :repository_branch
      t.boolean :resolve_errs_on_deploy, default: false
      t.boolean :notify_all_users, default: false
      t.boolean :notify_on_errs, default: true
      t.boolean :notify_on_deploys, default: false
      t.text :email_at_notices

      t.timestamps

    end
  end
end
