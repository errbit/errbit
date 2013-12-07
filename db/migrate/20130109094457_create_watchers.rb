class CreateWatchers < ActiveRecord::Migration
  def change
    create_table :watchers do |t|
      t.integer :app_id
      t.integer :user_id

      t.string :email
      t.timestamps
    end

    add_index :watchers, :app_id
    add_index :watchers, :user_id
  end
end
