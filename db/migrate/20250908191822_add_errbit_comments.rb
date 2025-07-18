# frozen_string_literal: true

class AddErrbitComments < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_comments do |t|
      t.string :bson_id

      t.references :errbit_user, null: false, foreign_key: true
      t.references :errbit_problem, null: false, foreign_key: true

      t.text :body

      t.timestamps null: false
    end

    add_index :errbit_comments, :bson_id, unique: true
  end
end
