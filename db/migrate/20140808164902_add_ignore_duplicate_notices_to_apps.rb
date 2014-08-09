class AddIgnoreDuplicateNoticesToApps < Mongoid::Migration
  def change
    add_column :apps, :ignore_duplicate_notices, :boolean
  end
end

