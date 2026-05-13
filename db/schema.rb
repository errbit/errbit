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

ActiveRecord::Schema[8.1].define(version: 2026_05_13_213042) do
  create_table "errbit_apps", force: :cascade do |t|
    t.string "api_key"
    t.string "asset_host"
    t.string "bitbucket_repo"
    t.string "bson_id"
    t.datetime "created_at", null: false
    t.string "current_app_version"
    t.string "custom_backtrace_url_template"
    t.text "email_at_notices"
    t.string "github_repo"
    t.string "name"
    t.boolean "notify_all_users", default: false, null: false
    t.boolean "notify_on_errs", default: true, null: false
    t.string "repository_branch"
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_errbit_apps_on_api_key", unique: true
    t.index ["bson_id"], name: "index_errbit_apps_on_bson_id", unique: true
    t.index ["name"], name: "index_errbit_apps_on_name", unique: true
  end

  create_table "errbit_backtraces", force: :cascade do |t|
    t.string "bson_id"
    t.datetime "created_at", null: false
    t.string "fingerprint"
    t.json "lines"
    t.datetime "updated_at", null: false
    t.index ["bson_id"], name: "index_errbit_backtraces_on_bson_id", unique: true
    t.index ["fingerprint"], name: "index_errbit_backtraces_on_fingerprint", unique: true
  end

  create_table "errbit_site_configs", force: :cascade do |t|
    t.boolean "action", default: true, null: false
    t.integer "backtrace_lines", default: -1
    t.string "bson_id"
    t.boolean "component", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "environment_name", default: true, null: false
    t.boolean "error_class", default: true, null: false
    t.boolean "message", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["bson_id"], name: "index_errbit_site_configs_on_bson_id", unique: true
  end

  create_table "errbit_users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "authentication_token"
    t.string "bson_id"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "github_login"
    t.string "github_oauth_token"
    t.string "google_uid"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.integer "per_page", default: 30
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "time_zone", default: "UTC"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["authentication_token"], name: "index_errbit_users_on_authentication_token", unique: true
    t.index ["bson_id"], name: "index_errbit_users_on_bson_id", unique: true
    t.index ["email"], name: "index_errbit_users_on_email", unique: true
    t.index ["github_login"], name: "index_errbit_users_on_github_login", unique: true
    t.index ["reset_password_token"], name: "index_errbit_users_on_reset_password_token", unique: true
  end

  create_table "errbit_watchers", force: :cascade do |t|
    t.string "bson_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "errbit_app_id", null: false
    t.integer "errbit_user_id"
    t.datetime "updated_at", null: false
    t.index ["bson_id"], name: "index_errbit_watchers_on_bson_id", unique: true
    t.index ["errbit_app_id"], name: "index_errbit_watchers_on_errbit_app_id"
    t.index ["errbit_user_id"], name: "index_errbit_watchers_on_errbit_user_id"
  end

  add_foreign_key "errbit_watchers", "errbit_apps"
  add_foreign_key "errbit_watchers", "errbit_users"
end
