# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140418180750) do

  create_table "apps", :force => true do |t|
    t.string   "name"
    t.string   "api_key"
    t.string   "github_repo"
    t.string   "bitbucket_repo"
    t.string   "asset_host"
    t.string   "repository_branch"
    t.boolean  "resolve_errs_on_deploy", :default => false
    t.boolean  "notify_all_users",       :default => false
    t.boolean  "notify_on_errs",         :default => true
    t.boolean  "notify_on_deploys",      :default => false
    t.text     "email_at_notices"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

  create_table "backtrace_lines", :force => true do |t|
    t.integer  "backtrace_id"
    t.integer  "column"
    t.integer  "number"
    t.text     "file"
    t.text     "method"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "backtrace_lines", ["backtrace_id"], :name => "index_backtrace_lines_on_backtrace_id"

  create_table "backtraces", :force => true do |t|
    t.string   "fingerprint"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "backtraces", ["fingerprint"], :name => "index_backtraces_on_fingerprint"

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "problem_id"
    t.text     "body"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "err_id"
  end

  add_index "comments", ["err_id"], :name => "index_comments_on_err_id"
  add_index "comments", ["problem_id"], :name => "index_comments_on_problem_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "deploys", :force => true do |t|
    t.string   "username"
    t.string   "repository"
    t.string   "environment"
    t.string   "revision"
    t.string   "message"
    t.integer  "app_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "deploys", ["app_id"], :name => "index_deploys_on_app_id"

  create_table "errs", :force => true do |t|
    t.integer  "problem_id"
    t.string   "fingerprint"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "errs", ["fingerprint"], :name => "index_errs_on_fingerprint"
  add_index "errs", ["problem_id"], :name => "index_errs_on_problem_id"

  create_table "issue_trackers", :force => true do |t|
    t.integer  "app_id"
    t.string   "project_id"
    t.string   "alt_project_id"
    t.string   "api_token"
    t.string   "type"
    t.string   "account"
    t.string   "username"
    t.string   "password"
    t.string   "ticket_properties"
    t.string   "subdomain"
    t.string   "milestone_id"
    t.string   "base_url"
    t.string   "context_path"
    t.string   "issue_type"
    t.string   "issue_component"
    t.string   "issue_priority"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "issue_trackers", ["app_id"], :name => "index_issue_trackers_on_app_id"

  create_table "notices", :force => true do |t|
    t.integer  "err_id"
    t.integer  "backtrace_id"
    t.text     "message"
    t.text     "server_environment"
    t.text     "request"
    t.text     "notifier"
    t.text     "user_attributes"
    t.string   "framework"
    t.text     "current_user"
    t.string   "error_class"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "notices", ["backtrace_id"], :name => "index_notices_on_backtrace_id"
  add_index "notices", ["err_id", "created_at", "id"], :name => "index_notices_on_err_id_and_created_at_and_id"

  create_table "notification_services", :force => true do |t|
    t.integer  "app_id"
    t.string   "room_id"
    t.string   "user_id"
    t.string   "service_url"
    t.string   "service"
    t.string   "api_token"
    t.string   "subdomain"
    t.string   "sender_name"
    t.string   "type"
    t.text     "notify_at_notices"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "notification_services", ["app_id"], :name => "index_notification_services_on_app_id"

  create_table "problems", :force => true do |t|
    t.integer  "app_id"
    t.datetime "last_notice_at"
    t.datetime "first_notice_at"
    t.datetime "last_deploy_at"
    t.boolean  "resolved"
    t.datetime "resolved_at"
    t.string   "issue_link"
    t.string   "issue_type"
    t.string   "app_name"
    t.integer  "notices_count"
    t.integer  "comments_count"
    t.text     "message"
    t.string   "environment"
    t.text     "error_class"
    t.string   "where"
    t.text     "user_agents"
    t.text     "messages"
    t.text     "hosts"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "first_notice_commit"
    t.string   "last_notice_commit"
  end

  add_index "problems", ["app_id"], :name => "index_problems_on_app_id"
  add_index "problems", ["app_name"], :name => "index_problems_on_app_name"
  add_index "problems", ["comments_count"], :name => "index_problems_on_comments_count"
  add_index "problems", ["first_notice_at"], :name => "index_problems_on_first_notice_at"
  add_index "problems", ["last_notice_at"], :name => "index_problems_on_last_notice_at"
  add_index "problems", ["message"], :name => "index_problems_on_message"
  add_index "problems", ["notices_count"], :name => "index_problems_on_notices_count"
  add_index "problems", ["resolved_at"], :name => "index_problems_on_resolved_at"

  create_table "users", :force => true do |t|
    t.string   "github_login"
    t.string   "github_oauth_token"
    t.string   "name"
    t.string   "username"
    t.boolean  "admin"
    t.integer  "per_page"
    t.string   "time_zone"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "watchers", :force => true do |t|
    t.integer  "app_id"
    t.integer  "user_id"
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "watchers", ["app_id"], :name => "index_watchers_on_app_id"
  add_index "watchers", ["user_id"], :name => "index_watchers_on_user_id"

end
