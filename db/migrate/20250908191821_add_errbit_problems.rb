# frozen_string_literal: true

class AddErrbitProblems < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_problems do |t|
      t.references :errbit_app, null: false, foreign_key: true

      t.string :error_class
      t.string :environment

      t.timestamps null: false
    end
  end
end
