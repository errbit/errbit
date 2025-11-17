# frozen_string_literal: true

class AddProblems < ActiveRecord::Migration[8.0]
  def change
    create_table :errbit_problems do |t|
      t.timestamps null: false
    end
  end
end
