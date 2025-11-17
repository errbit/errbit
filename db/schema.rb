# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_08_191821) do
  create_table "errbit_apps", force: :cascade do |t|
    t.string "name"
    t.string "github_repo"
    t.string "bitbucket_repo"
    t.string "repository_branch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "errbit_problems", force: :cascade do |t|
    t.integer "errbit_app_id", null: false
    t.string "error_class"
    t.string "environment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["errbit_app_id"], name: "index_errbit_problems_on_errbit_app_id"
  end

  create_table "errbit_users", force: :cascade do |t|
    t.string "bson_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "authentication_token"
    t.string "name"
    t.string "username"
    t.boolean "admin", default: false, null: false
    t.integer "per_page", default: 30
    t.string "time_zone", default: "UTC"
    t.string "github_login"
    t.string "github_oauth_token"
    t.string "google_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bson_id"], name: "index_errbit_users_on_bson_id", unique: true
    t.index ["email"], name: "index_errbit_users_on_email", unique: true
    t.index ["github_login"], name: "index_errbit_users_on_github_login", unique: true
    t.index ["reset_password_token"], name: "index_errbit_users_on_reset_password_token", unique: true
  end

  create_table "errbit_watchers", force: :cascade do |t|
    t.integer "errbit_user_id"
    t.integer "errbit_app_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["errbit_app_id"], name: "index_errbit_watchers_on_errbit_app_id"
    t.index ["errbit_user_id"], name: "index_errbit_watchers_on_errbit_user_id"
  end

  add_foreign_key "errbit_problems", "errbit_apps"
  add_foreign_key "errbit_watchers", "errbit_apps"
  add_foreign_key "errbit_watchers", "errbit_users"
end
