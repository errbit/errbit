class CreateBacktraces < ActiveRecord::Migration
  def change
    create_table :backtraces do |t|
      t.string :fingerprint
      t.timestamps
    end

    add_index :backtraces, :fingerprint
  end
end
