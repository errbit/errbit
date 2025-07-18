# frozen_string_literal: true

class AddErrbitNoticeFingerprinters < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_notice_fingerprinters do |t|
      t.string :bson_id

      t.references :errbit_app, null: false, foreign_key: true

      t.boolean :error_class, null: false, default: true
      t.boolean :message, null: false, default: true
      t.integer :backtrace_lines, default: -1
      t.boolean :component, null: false, default: true
      t.boolean :action, null: false, default: true
      t.boolean :environment_name, null: false, default: true
      t.string :source

      t.timestamps null: false
    end

    add_index :errbit_notice_fingerprinters, :bson_id, unique: true
  end
end
