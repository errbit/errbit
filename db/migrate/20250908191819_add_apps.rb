# frozen_string_literal: true

class AddApps < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_apps do |t|
      t.timestamps null: false
    end
  end
end
