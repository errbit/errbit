# frozen_string_literal: true

class AddErrbitWatchers < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_watchers do |t|
      t.string :bson_id

      t.references :errbit_user, null: true, foreign_key: true
      t.references :errbit_app, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :errbit_watchers, :bson_id, unique: true
  end
end
