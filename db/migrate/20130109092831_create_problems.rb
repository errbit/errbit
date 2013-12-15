class CreateProblems < ActiveRecord::Migration
  def change
    create_table :problems do |t|
      t.integer :app_id

      t.datetime :last_notice_at
      t.datetime :first_notice_at
      t.datetime :last_deploy_at
      t.boolean :resolved
      t.datetime :resolved_at
      t.string :issue_link
      t.string :issue_type

      t.string :app_name
      t.integer :notices_count
      t.integer :comments_count
      t.text :message
      t.string :environment
      t.text :error_class
      t.string :where
      t.text :user_agents
      t.text :messages
      t.text :hosts

      t.timestamps
    end

    add_index :problems, :app_id
    add_index :problems, :app_name
    add_index :problems, :message
    add_index :problems, :last_notice_at
    add_index :problems, :first_notice_at
    add_index :problems, :resolved_at
    add_index :problems, :notices_count
    add_index :problems, :comments_count
  end
end
