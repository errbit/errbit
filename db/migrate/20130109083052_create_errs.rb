class CreateErrs < ActiveRecord::Migration
  def change
    create_table :errs do |t|
      t.integer :problem_id
      t.string :fingerprint

      t.timestamps
    end

    add_index :errs, :problem_id
    add_index :errs, :fingerprint
  end
end
