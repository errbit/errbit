class CreateDeploy < ActiveRecord::Migration
  def change
    create_table :deploys do |t|
      t.string :username
      t.string :repository
      t.string :environment
      t.string :revision
      t.string :message
      t.integer :app_id

      t.timestamps
    end

    add_index :deploys, :app_id
  end
end
