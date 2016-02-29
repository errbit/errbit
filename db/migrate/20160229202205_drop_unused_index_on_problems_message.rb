class DropUnusedIndexOnProblemsMessage < ActiveRecord::Migration
  def up
    remove_index :problems, :message
  end

  def down
    add_index :problems, :message
  end
end
