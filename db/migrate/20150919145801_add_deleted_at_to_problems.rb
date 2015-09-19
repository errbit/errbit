class AddDeletedAtToProblems < ActiveRecord::Migration
  def change
    add_column :problems, :deleted_at, :timestamp
  end
end
