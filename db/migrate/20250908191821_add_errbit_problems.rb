# frozen_string_literal: true

class AddErrbitProblems < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_problems do |t|
      t.string :bson_id

      t.references :errbit_app, null: false, foreign_key: true

      t.string :error_class
      t.string :environment

      t.timestamps null: false
    end

    add_index :errbit_problems, :bson_id, unique: true
  end
end
