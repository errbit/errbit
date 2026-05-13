# frozen_string_literal: true

class CreateErrbitWatchers < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_watchers do |t|
      t.string :bson_id
      t.references :errbit_app, null: false, foreign_key: true
      t.references :errbit_user, foreign_key: true
      t.string :email

      t.timestamps
    end

    add_index :errbit_watchers, :bson_id, unique: true
  end
end
