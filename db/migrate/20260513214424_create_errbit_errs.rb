# frozen_string_literal: true

class CreateErrbitErrs < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_errs do |t|
      t.string :bson_id
      t.references :errbit_problem, null: false, foreign_key: true
      t.string :fingerprint

      t.timestamps
    end

    add_index :errbit_errs, :bson_id, unique: true
    add_index :errbit_errs, :fingerprint
  end
end
