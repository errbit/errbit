class CreateBacktraceLines < ActiveRecord::Migration
  def change
    create_table :backtrace_lines do |t|
      t.integer :backtrace_id
      t.integer :column
      t.integer :number
      t.text :file
      t.text :method

      t.timestamps
    end

    add_index :backtrace_lines, :backtrace_id
  end
end
