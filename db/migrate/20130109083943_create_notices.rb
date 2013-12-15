class CreateNotices < ActiveRecord::Migration
  def change
    create_table :notices do |t|
      t.integer :err_id
      t.integer :backtrace_id
      t.text :message
      t.text :server_environment
      t.text :request
      t.text :notifier
      t.text :user_attributes
      t.string :framework
      t.text :current_user
      t.string :error_class

      t.timestamps
    end

    add_index :notices, [:err_id, :created_at, :id]
    add_index :notices, :backtrace_id
  end
end
