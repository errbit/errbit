class AddOpenedAtToProblems < ActiveRecord::Migration
  def up
    add_column :problems, :opened_at, :timestamp
    execute "UPDATE problems SET opened_at=created_at"
    change_column_null :problems, :opened_at, false
  end

  def down
    remove_column :problems, :opened_at
  end
end
