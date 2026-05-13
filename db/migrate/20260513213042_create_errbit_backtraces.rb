# frozen_string_literal: true

class CreateErrbitBacktraces < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_backtraces do |t|
      t.string :bson_id
      t.string :fingerprint
      t.json :lines

      t.timestamps
    end

    add_index :errbit_backtraces, :bson_id, unique: true
    add_index :errbit_backtraces, :fingerprint, unique: true
  end
end
