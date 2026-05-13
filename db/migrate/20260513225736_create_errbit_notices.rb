# frozen_string_literal: true

class CreateErrbitNotices < ActiveRecord::Migration[8.1]
  def change
    create_table :errbit_notices do |t|
      t.string :bson_id
      t.references :errbit_app, null: false, foreign_key: true
      t.references :errbit_err, null: false, foreign_key: true
      t.references :errbit_backtrace, null: false, foreign_key: true

      t.text :message
      t.string :framework
      t.string :error_class

      t.json :server_environment
      t.json :request
      t.json :notifier
      t.json :user_attributes

      t.timestamps
    end

    add_index :errbit_notices, :bson_id, unique: true
    add_index :errbit_notices, :created_at
    add_index :errbit_notices, [:errbit_err_id, :created_at, :id], name: "index_errbit_notices_on_err_created_id"
  end
end
