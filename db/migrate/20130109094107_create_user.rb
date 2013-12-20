class CreateUser < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :github_login
      t.string :github_oauth_token
      t.string :name
      t.string :username
      t.boolean :admin
      t.integer :per_page
      t.string :time_zone

      t.timestamps
    end
  end
end
