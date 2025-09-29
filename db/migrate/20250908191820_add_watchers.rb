# frozen_string_literal: true

class AddWatchers < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_watchers do |t|
      t.references :user, null: true, foreign_key: true
      t.references :app, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
