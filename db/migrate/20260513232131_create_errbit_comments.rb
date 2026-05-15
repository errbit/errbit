# frozen_string_literal: true

class CreateErrbitComments < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_comments do |t|
      t.string :bson_id
      t.references :errbit_problem, null: false, foreign_key: true
      t.references :errbit_user, null: false, foreign_key: true
      t.text :body

      t.timestamps
    end

    add_index :errbit_comments, :bson_id, unique: true
  end
end
