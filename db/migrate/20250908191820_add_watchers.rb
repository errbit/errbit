# frozen_string_literal: true

class AddWatchers < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_watchers do |t|
      t.references :errbit_user, null: true, foreign_key: true
      t.references :errbit_app, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
