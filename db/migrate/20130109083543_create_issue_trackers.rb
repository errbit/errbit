class CreateIssueTrackers < ActiveRecord::Migration
  def change
    create_table :issue_trackers do |t|
      t.integer :app_id
      t.string :project_id
      t.string :alt_project_id
      t.string :api_token
      t.string :type
      t.string :account
      t.string :username
      t.string :password
      t.string :ticket_properties
      t.string :subdomain
      t.string :milestone_id

      t.string :base_url
      t.string :context_path
      t.string :issue_type
      t.string :issue_component
      t.string :issue_priority
      t.timestamps
    end

    add_index :issue_trackers, :app_id
  end
end
