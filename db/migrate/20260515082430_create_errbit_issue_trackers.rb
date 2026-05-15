# frozen_string_literal: true

class CreateErrbitIssueTrackers < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_issue_trackers do |t|
      t.string :bson_id
      t.references :errbit_app, foreign_key: true, index: {unique: true}

      t.string :type_tracker
      t.json :options

      t.timestamps
    end

    add_index :errbit_issue_trackers, :bson_id, unique: true
  end
end
