class MongodbDataStubs
  class << self
    def apps
      [{
        "_id" => "04f2a83052892bcb7d82d2d708cf8e3f",
        "api_key" => "f4e172e2723e430b25fc49218a345c13",
        "email_at_notices" => [1, 3, 5, 10, 20],
        "github_repo" => "git://github.com/errbit/errbit",
        "name" => "Errbit",
        "notify_all_users" => false,
        "notify_on_deploys" => true,
        "notify_on_deploys_with_changelog" => true,
        "notify_on_errs" => true,
        "resolve_errs_on_deploy" => false,
        "created_at" => Time.parse("2011-01-01 00:00:00"),
        "updated_at" => Time.parse("2013-01-01 00:00:00"),
        "issue_tracker" => {
          "_id" => BSON::ObjectId('506556023012d243a80116b4'),
          "_type" => "IssueTrackers::RedmineTracker",
          "account" => "http://example.com/",
          "api_token" => "23bdfbc990eb8545ac55e540bd5217f2c56fa6b4",
          "project_id" => "errbit",
          "alt_project_id" => "",
          "updated_at" => Time.parse("2013-01-01 00:00:00"),
          "created_at" => Time.parse("2013-01-01 00:00:00")
        },
        "notification_service" => {
          "_id" => BSON::ObjectId('506556023012d243a80116b4'),
          "_type" => "NotificationServices::GtalkService",
          "subdomain" => "username@example.com",
          "api_token" => "password",
          "user_id" => "touser@example.com",
          "room_id" => "toroom@conference.example.com",
          "service" => "talk.google.com",
          "service_url" => "http://www.google.com/talk/",
          "updated_at" => Time.parse("2013-01-01 00:00:00"),
          "created_at" => Time.parse("2013-01-01 00:00:00")
        },
        "watchers" => [
          {"user_id" => BSON::ObjectId('4e0c4abd3012d27b15000001'), "_id"=>BSON::ObjectId('4f6889b63012d23c8700374b'), "email" => nil},
          {"user_id" => nil, "_id"=>BSON::ObjectId('4f699cdc3012d23c930036d3'), "email" => "email@example.com"}
        ],
        "deploys" => [
          {"username" => "errbit", "environment" => "production", "repository" => "git://github.com/errbit/errbit.git", "revision" => "c4a4ec5ecdfbbdf58194c0f9b8e89575685c5618", "message" => nil, "_id" => BSON::ObjectId('5072d8f53012d243a8013961'), "updated_at" => Time.parse("2013-01-01 00:00:00"), "created_at" => Time.parse("2013-01-01 00:00:00")}
        ]
      }]
    end

    def problems
      [{
        "_id" => BSON::ObjectId('4fec4aaf3012d25934008404'),
        "app_id" => "04f2a83052892bcb7d82d2d708cf8e3f",
        "app_name" => "Errbit",
        "comments_count" => 0,
        "environment" => "production",
        "first_notice_at" => Time.parse("2013-01-01 00:00:00"),
        "hosts" => {},
        "last_deploy_at" => Time.parse("2013-01-01 00:00:00"),
        "last_notice_at" => Time.parse("2013-01-01 00:00:00"),
        "message" => "[undefined method]",
        "messages" => {},
        "notices_count" => 1,
        "resolved" => false,
        "user_agents" => {},
        "where" => "self#unknown",
        "created_at" => Time.parse("2012-01-01 00:00:00"),
        "updated_at" => Time.parse("2013-01-01 00:00:00")
      }]
    end

    def users
      [{
        "_id" => BSON::ObjectId('4e0c4abd3012d27b15000001'),
        "admin" => true,
        "authentication_token" => "stV0c_BfpI0iPki5YXB7",
        "current_sign_in_at" => Time.parse("2013-01-01 00:00:00"),
        "current_sign_in_ip" => "127.0.0.1",
        "email" => "admin@example.com",
        "encrypted_password" => "$2a$10$D.KOt.7xCMB8BOZACz7Kiu6VG9Vf32NPPGZC631DDI.idDyas5LBm",
        "last_sign_in_at" => Time.parse("2013-01-01 00:00:00"),
        "last_sign_in_ip" => "127.0.0.1",
        "name" => "Errbit Admin",
        "password_salt" => "$2a$10$D.KOt.7xCMB8BOZACz7Kiu",
        "per_page" => 100,
        "remember_created_at" => nil,
        "remember_token" => nil,
        "sign_in_count" => 400,
        "time_zone" => "UTC",
        "created_at" => Time.parse("2011-01-01 00:00:00"),
        "updated_at" => Time.parse("2013-01-01 00:00:00")
      }]
    end

    def comments
      [{
        "_id" => BSON::ObjectId('4ed884063012d2101c0000cf'),
        "body" => "body comment",
        "user_id" => BSON::ObjectId('4e0c4abd3012d27b15000001'),
        "err_id" => BSON::ObjectId('4fec4aaf3012d25934008404'),
        "updated_at" => Time.parse("2011-12-02 07:53:42"),
        "created_at" => Time.parse("2011-12-02 07:53:42")
      }]
    end

    def errs
      [{
        "_id" => BSON::ObjectId('4e0c62753012d201b700000e'),
        "error_class" => "UnknownError",
        "environment" => "production",
        "component" => "application",
        "action" => "verify",
        "fingerprint" => "683265bbcfd2b364500eec64cd48af3b23b70b73",
        "problem_id" => BSON::ObjectId('4fec4aaf3012d25934008404'),
        "created_at" => Time.parse("2011-06-30 11:48:05"),
        "updated_at" => Time.parse("2013-01-22 02:39:16")
      }]
    end

    def notices
      [{
        "_id" => BSON::ObjectId('51028d4c3012d22b730012d0'),
        "message" => "[undefined method]",
        "error_class" => "UnknownError",
        "backtrace_id" => BSON::ObjectId('510268443012d21a61000cfd'),
        "request" => {"url" => {}, "component" => "self", "action" => "unknown"},
        "server_environment" => {"environment-name" => "production", "hostname" => "errbit.github.com"},
        "notifier" => {"name" => "Airbrake Notifier", "version" => "3.1.1", "url" => "https://github.com/airbrake/airbrake"},
        "user_attributes" => {},
        "current_user" => {},
        "framework" => "Rails",
        "err_id" => BSON::ObjectId('4e0c62753012d201b700000e'),
        "updated_at" => Time.parse("2013-01-01 00:00:00"),
        "created_at" => Time.parse("2013-01-01 00:00:00")
      }]
    end

    def backtraces
      [{
        "_id" => BSON::ObjectId('510268443012d21a61000cfd'),
        "fingerprint" => "8e99be04c8c20930cd8d014e750ef229741a9a3e",
        "updated_at" => Time.parse("2013-01-21 12:01:13"),
        "created_at" => Time.parse("2013-01-21 12:01:13"),
        "lines" => [{
          "_id" => BSON::ObjectId('50fd2e093012d20a2300003c'),
          "number" => 1,
          "file" => "[GEM_ROOT]/path/to/file.rb",
          "method"=>"invoke"
        }]
      }]
    end

    def db(name)
      {
        name => {
          :apps => apps,
          :users => users,
          :problems => problems,
          :comments => comments,
          :errs => errs,
          :notices => notices,
          :backtraces => backtraces
        }
      }
    end
  end
end
