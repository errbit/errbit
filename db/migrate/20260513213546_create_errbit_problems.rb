# frozen_string_literal: true

class CreateErrbitProblems < ActiveRecord::Migration[8.1]
  def change
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
      t.string :message
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
  end
end
