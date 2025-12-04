# frozen_string_literal: true

class AddErrbitSiteConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_site_configs do |t|
      t.string :bson_id

      t.boolean :error_class, null: false, default: true
      t.boolean :message, null: false, default: true
      t.integer :backtrace_lines, default: -1
      t.boolean :component, null: false, default: true
      t.boolean :action, null: false, default: true
      t.boolean :environment_name, null: false, default: true

      t.timestamps null: false
    end

    add_index :errbit_site_configs, :bson_id, unique: true
  end
end
