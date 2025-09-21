# frozen_string_literal: true

class AddWatchers < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_watchers do |t|
      t.bigint :user_id

      t.timestamps null: false
    end
  end
end
