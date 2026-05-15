# frozen_string_literal: true

class CreateErrbitNoticeFingerprinters < ActiveRecord::Migration[8.1]
  def change
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
  end
end
