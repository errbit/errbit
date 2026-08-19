# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "errbit:migrate" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def invoke(task_name)
    task = Rake::Task["errbit:migrate:#{task_name}"]
    task.reenable
    task.invoke
  end

  def with_env(key, value)
    previous = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = previous
  end

  describe ":users" do
    it "creates SQL users linked by bson_id and is idempotent" do
      mongo_user = create(:user, email: "ported@example.com", name: "Ported", admin: true)

      expect { invoke(:users) }.to change(Errbit::User, :count).by(1)

      sql_user = Errbit::User.find_by!(bson_id: mongo_user.id.to_s)
      expect(sql_user.email).to eq("ported@example.com")
      expect(sql_user.name).to eq("Ported")
      expect(sql_user.admin).to eq(true)

      mongo_user.update!(name: "Renamed")
      expect { invoke(:users) }.not_to change(Errbit::User, :count)
      expect(sql_user.reload.name).to eq("Renamed")
    end

    it "migrates OAuth-only users without passwords" do
      mongo_user = create(:user, password: nil, github_login: "octocat", github_oauth_token: "token")

      invoke(:users)

      sql_user = Errbit::User.find_by!(bson_id: mongo_user.id.to_s)
      expect(sql_user.github_login).to eq("octocat")
      expect(sql_user.github_oauth_token).to eq("token")
      expect(sql_user.encrypted_password).to eq("")
    end
  end

  describe ":apps" do
    it "creates SQL apps linked by bson_id" do
      mongo_app = create(:app, name: "Mongo App", github_repo: "errbit/errbit", email_at_notices: [1, 5])

      expect { invoke(:apps) }.to change(Errbit::App, :count).by(1)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      expect(sql_app.name).to eq("Mongo App")
      expect(sql_app.github_repo).to eq("errbit/errbit")
      expect(sql_app.attributes["email_at_notices"]).to eq([1, 5])
    end
  end

  describe ":all" do
    it "migrates representative Mongo data into related SQL rows" do
      mongo_user = create(:user, email: "watcher@example.com", name: "Watcher")
      mongo_app = create(:app, name: "Full App", notify_on_errs: false)
      mongo_app.watchers.create!(user_id: mongo_user.id)
      mongo_app.watchers.create!(email: "external@example.com")
      mongo_app.build_issue_tracker(type_tracker: "mock", options: {"foo" => "bar"})
      mongo_app.build_notification_service(_type: "NotificationServices::SlackService", service_url: "https://hooks.slack.com/services/T/B/C", room_id: "#errors")
      mongo_app.notice_fingerprinter.update!(message: false, backtrace_lines: 3, source: SiteConfig::CONFIG_SOURCE_APP)
      mongo_app.save!

      mongo_problem = create(:problem, app: mongo_app, environment: "production", error_class: "RuntimeError", message: "boom", comments_count: 1)
      mongo_err = create(:err, problem: mongo_problem, fingerprint: "full-fingerprint")
      mongo_backtrace = create(:backtrace, lines: [{"file" => "app.rb", "number" => 1}])
      mongo_notice = create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        message: "notice message",
        server_environment: {"environment-name" => "production"},
        request: {"url" => "https://example.com"},
        notifier: {"name" => "rspec"})
      mongo_comment = create(:comment, err: mongo_problem, user: mongo_user, body: "comment body")

      invoke(:all)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      sql_user = Errbit::User.find_by!(bson_id: mongo_user.id.to_s)
      sql_problem = Errbit::Problem.find_by!(bson_id: mongo_problem.id.to_s)
      sql_err = Errbit::Err.find_by!(bson_id: mongo_err.id.to_s)
      sql_backtrace = Errbit::Backtrace.find_by!(bson_id: mongo_backtrace.id.to_s)
      sql_notice = Errbit::Notice.find_by!(bson_id: mongo_notice.id.to_s)
      sql_comment = Errbit::Comment.find_by!(bson_id: mongo_comment.id.to_s)

      expect(sql_app.watchers.map(&:address)).to contain_exactly("watcher@example.com", "external@example.com")
      expect(sql_app.issue_tracker.options["foo"]).to eq("bar")
      expect(sql_app.notification_service).to be_a(Errbit::NotificationServices::SlackService)
      expect(sql_app.notice_fingerprinter.message).to eq(false)
      expect(sql_problem.app).to eq(sql_app)
      expect(sql_problem.comments_count).to eq(mongo_problem.reload.comments_count)
      expect(sql_err.problem).to eq(sql_problem)
      expect(sql_backtrace.lines.first["file"]).to eq("app.rb")
      expect(sql_notice.app).to eq(sql_app)
      expect(sql_notice.err).to eq(sql_err)
      expect(sql_notice.backtrace).to eq(sql_backtrace)
      expect(sql_comment.err).to eq(sql_problem)
      expect(sql_comment.user).to eq(sql_user)

      counts = {
        users: Errbit::User.count,
        apps: Errbit::App.count,
        problems: Errbit::Problem.count,
        errs: Errbit::Err.count,
        backtraces: Errbit::Backtrace.count,
        notices: Errbit::Notice.count,
        comments: Errbit::Comment.count
      }

      invoke(:all)

      expect { invoke(:verify) }.not_to raise_error

      expect(Errbit::User.count).to eq(counts[:users])
      expect(Errbit::App.count).to eq(counts[:apps])
      expect(Errbit::Problem.count).to eq(counts[:problems])
      expect(Errbit::Err.count).to eq(counts[:errs])
      expect(Errbit::Backtrace.count).to eq(counts[:backtraces])
      expect(Errbit::Notice.count).to eq(counts[:notices])
      expect(Errbit::Comment.count).to eq(counts[:comments])
    end

    it "migrates partial embedded app records and BSON-shaped hashes" do
      mongo_user = create(:user, email: "embedded@example.com")
      mongo_app = create(:app, name: "Partial Embedded")
      mongo_app.watchers.create!(user_id: mongo_user.id)
      mongo_app.watchers.create!(email: "raw@example.com")
      mongo_app.build_issue_tracker(type_tracker: nil, options: {"$token" => {"nested.key" => "value"}})
      mongo_app.build_notification_service(_type: "NotificationServices::SlackService", service_url: "https://hooks.slack.com/services/T/B/C", notify_at_notices: nil)
      mongo_app.save!(validate: false)

      mongo_problem = create(:problem, app: mongo_app, messages: {"$message.key" => {"value" => "boom", "count" => 1}})
      mongo_err = create(:err, problem: mongo_problem)
      mongo_backtrace = create(:backtrace, lines: [{"file.name" => "app.rb", "$number" => 1}])
      create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        message: "x" * 1200,
        request: {"$params" => {"nested.key" => "value"}},
        server_environment: {"environment-name" => "production"},
        notifier: {"name" => "rspec"})
      mongo_problem.update!(messages: {"$message.key" => {"value" => "boom", "count" => 1}})

      invoke(:all)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      sql_problem = Errbit::Problem.find_by!(bson_id: mongo_problem.id.to_s)
      sql_notice = Errbit::Notice.first

      expect(sql_app.watchers.map(&:address)).to contain_exactly("embedded@example.com", "raw@example.com")
      expect(sql_app.issue_tracker.options["$token"]["nested.key"]).to eq("value")
      expect(sql_app.notification_service).to be_a(Errbit::NotificationServices::SlackService)
      expect(sql_app.notification_service.notify_at_notices).to eq([0])
      expect(sql_problem.messages["$message.key"]["value"]).to eq("boom")
      expect(sql_notice.message.bytesize).to eq(1000)
      expect(sql_notice.request["&#36;params"]["nested&#46;key"]).to eq("value")
      expect(Errbit::Backtrace.find_by!(bson_id: mongo_backtrace.id.to_s).lines.first["file.name"]).to eq("app.rb")
    end

    it "can resume after a strict migration failure without duplicating existing rows" do
      mongo_user = create(:user, email: "resume@example.com", name: "Before Resume")
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      mongo_err = create(:err, problem: mongo_problem)

      notice_id = BSON::ObjectId.new
      Notice.collection.insert_one(
        _id: notice_id,
        app_id: mongo_app.id,
        err_id: mongo_err.id,
        backtrace_id: BSON::ObjectId.new,
        message: "resume notice",
        error_class: "RuntimeError",
        server_environment: {"environment-name" => "production"},
        request: {},
        notifier: {"name" => "rspec"},
        created_at: Time.current,
        updated_at: Time.current
      )

      with_env("ERRBIT_MIGRATE_STRICT", "true") do
        expect { invoke(:all) }
          .to raise_error(RuntimeError, /migration failed for notices with 1 failed row/)
      end

      counts_after_failure = {
        users: Errbit::User.count,
        apps: Errbit::App.count,
        problems: Errbit::Problem.count,
        errs: Errbit::Err.count,
        notices: Errbit::Notice.count
      }
      expect(counts_after_failure).to include(users: 1, apps: 1, problems: 1, errs: 1, notices: 0)

      mongo_backtrace = create(:backtrace, lines: [{"file" => "resume.rb", "number" => 1}])
      Notice.collection.find(_id: notice_id).update_one("$set" => {backtrace_id: mongo_backtrace.id})
      mongo_user.update!(name: "After Resume")

      with_env("ERRBIT_MIGRATE_STRICT", "true") do
        expect { invoke(:all) }.not_to raise_error
      end

      expect(Errbit::User.count).to eq(counts_after_failure[:users])
      expect(Errbit::App.count).to eq(counts_after_failure[:apps])
      expect(Errbit::Problem.count).to eq(counts_after_failure[:problems])
      expect(Errbit::Err.count).to eq(counts_after_failure[:errs])
      expect(Errbit::Notice.count).to eq(1)
      expect(Errbit::User.find_by!(bson_id: mongo_user.id.to_s).name).to eq("After Resume")
      expect(Errbit::Notice.find_by!(bson_id: notice_id.to_s).backtrace.bson_id).to eq(mongo_backtrace.id.to_s)
    end
  end

  describe "strict failure mode" do
    it "raises when a task records failed rows" do
      create(:problem)

      with_env("ERRBIT_MIGRATE_STRICT", "true") do
        expect { invoke(:problems) }
          .to raise_error(RuntimeError, /migration failed for problems with 1 failed row/)
      end
    end

    it "does not raise by default when a task records failed rows" do
      create(:problem)

      expect { invoke(:problems) }.not_to raise_error
    end
  end

  describe ":verify" do
    it "fails when migrated problem cached state does not match Mongo" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app, notices_count: 2)
      create(:err, problem: mongo_problem)

      invoke(:all)

      Errbit::Problem.find_by!(bson_id: mongo_problem.id.to_s).update_columns(notices_count: 99)

      expect { invoke(:verify) }
        .to raise_error(RuntimeError, /migration verification failed with 1 issue/)
    end

    it "fails when a migrated relationship is missing" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      create(:err, problem: mongo_problem)

      invoke(:all)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      ActiveRecord::Base.connection.disable_referential_integrity { sql_app.delete }

      expect { invoke(:verify) }
        .to raise_error(RuntimeError, /migration verification failed with 2 issue/)
    end
  end

  describe "side effects" do
    it "restores migration import mode after errors" do
      Errbit.migrating = false

      expect do
        Errbit::MigrateHelpers.with_import_mode { raise "boom" }
      end.to raise_error("boom")

      expect(Errbit).not_to be_migrating
    end

    it "does not deliver comment emails during migration imports" do
      mongo_user = create(:user)
      mongo_app = create(:app, notify_on_errs: true)
      mongo_app.watchers.create!(email: "watcher@example.com")
      mongo_problem = create(:problem, app: mongo_app)
      Comment.collection.insert_one(
        body: "imported comment",
        err_id: mongo_problem.id,
        user_id: mongo_user.id,
        created_at: Time.current,
        updated_at: Time.current
      )

      expect(Errbit::Mailer).not_to receive(:with)

      invoke(:all)
    end

    it "does not deliver error report emails or service notifications in import mode" do
      app = create(:errbit_app, notify_on_errs: true, email_at_notices: [0])
      create(:errbit_watcher, app: app, email: "watcher@example.com")
      create(:errbit_webhook_service, app: app)

      report = Errbit::ErrorReport.new(
        api_key: app.api_key,
        error_class: "RuntimeError",
        message: "import mode boom",
        backtrace: [{"file" => "app.rb", "number" => 1, "method" => "call"}],
        request: {"component" => "imports", "action" => "create", "url" => "https://example.test"},
        server_environment: {"environment-name" => "production"},
        notifier: {"name" => "rspec"}
      )

      expect(Errbit::Mailer).not_to receive(:with)
      expect_any_instance_of(Errbit::NotificationServices::WebhookService).not_to receive(:create_notification)

      Errbit::MigrateHelpers.with_import_mode { report.generate_notice! }
    end

    it "does not denormalize app names in import mode" do
      app = create(:errbit_app, name: "Original App")
      problem = create(:errbit_problem, app: app, app_name: "Original App")

      Errbit::MigrateHelpers.with_import_mode { app.update!(name: "Imported App") }

      expect(problem.reload.app_name).to eq("Original App")
    end

    it "does not denormalize site fingerprinters in import mode" do
      app = create(:errbit_app)
      app.notice_fingerprinter.update!(message: true, source: Errbit::SiteConfig::CONFIG_SOURCE_SITE)
      site_config = create(:errbit_site_config, message: true)

      Errbit::MigrateHelpers.with_import_mode { site_config.update!(message: false) }

      expect(app.notice_fingerprinter.reload.message).to eq(true)
    end

    it "does not recache problems when notices are destroyed in import mode" do
      problem = create(:errbit_problem, notices_count: 5)
      err = create(:errbit_err, problem: problem)
      notice = create(:errbit_notice, err: err)
      problem.update_columns(notices_count: 5)

      Errbit::MigrateHelpers.with_import_mode { notice.destroy! }

      expect(problem.reload.notices_count).to eq(5)
    end
  end

  describe "production data shapes" do
    it "migrates notices with attack payloads without corruption" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      mongo_err = create(:err, problem: mongo_problem)
      mongo_backtrace = create(:backtrace, lines: [{"file" => "app.rb", "number" => 1}])
      mongo_notice = create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        message: "ActionDispatch::Http::MimeNegotiation::InvalidType: \"../../../../../../../../../../etc/services{{\" is not a valid MIME type",
        server_environment: {"environment-name" => "production"},
        notifier: {"name" => "airbrake"},
        error_class: "ActionDispatch::Http::MimeNegotiation::InvalidType")

      invoke(:all)

      sql_notice = Errbit::Notice.find_by!(bson_id: mongo_notice.id.to_s)

      expect(sql_notice.message).to include("../../../")
      expect(sql_notice.message).to include("{{")
      expect(sql_notice.error_class).to eq("ActionDispatch::Http::MimeNegotiation::InvalidType")
    end

    it "preserves large hash distributions in cached problem attributes" do
      mongo_app = create(:app)
      mongo_problem = create(:problem,
        app: mongo_app,
        user_agents: {
          "dc00bef7e8c25c784d905ac8639b027c" => {"value" => "Chrome 60.0.3112.113 (Windows 10)", "count" => 1140},
          "1140e65909cc5a48ecbbc1f2ab12ee0e" => {"value" => "Chrome 123.0.6312.86 ()", "count" => 3},
          "d5bdbe02c8d406bf1abadda0441ac0d9" => {"value" => "Safari 14.1.1 (OS X 10.15.6)", "count" => 8}
        },
        hosts: {
          "7c6845b7e2f69d04ae20652df7dd8e80" => {"value" => "10.0.0.1", "count" => 10}
        },
        messages: {
          "39363b3685df81a25a3d03e2f0af075e" => {"value" => "ActionDispatch::Http::MimeNegotiation::InvalidType", "count" => 10}
        })

      invoke(:all)

      sql_problem = Errbit::Problem.find_by(bson_id: mongo_problem.id.to_s)
      expect(sql_problem.user_agents.keys).to eq(mongo_problem.user_agents.keys)
      expect(sql_problem.user_agents.values.map { |v| v["count"] }).to contain_exactly(1140, 3, 8)
      expect(sql_problem.hosts["7c6845b7e2f69d04ae20652df7dd8e80"]["value"]).to eq("10.0.0.1")
      expect(sql_problem.messages["39363b3685df81a25a3d03e2f0af075e"]["count"]).to eq(10)
    end

    it "handles problems with notices_count of 0" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app, notices_count: 0, comments_count: 0)
      mongo_problem.update!(notices_count: 0)

      invoke(:all)

      sql_problem = Errbit::Problem.find_by(bson_id: mongo_problem.id.to_s)
      expect(sql_problem.notices_count).to eq(0)
      expect(sql_problem.comments_count).to eq(0)
    end

    it "migrates base NotificationService with no subclass fields" do
      mongo_app = create(:app, name: "Base Service App")
      App.collection.find_one_and_update(
        {_id: mongo_app.id},
        {"$set" => {
          "notification_service._id" => BSON::ObjectId.new.to_s,
          "notification_service._type" => "NotificationService",
          "notification_service.notify_at_notices" => []
        }}
      )

      invoke(:all)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      expect(sql_app.notification_service).to be_a(Errbit::NotificationService)
      expect(sql_app.notification_service.class).not_to be < Errbit::NotificationServices
    end

    it "migrates problems with resolved_at timestamps" do
      mongo_app = create(:app)
      mongo_problem = create(:problem,
        app: mongo_app,
        resolved: true,
        resolved_at: Time.utc(2026, 7, 16, 9, 8, 10),
        notices_count: 10)

      invoke(:all)

      sql_problem = Errbit::Problem.find_by(bson_id: mongo_problem.id.to_s)
      expect(sql_problem.resolved).to eq(true)
      expect(sql_problem.resolved_at).to be_a(Time)
      expect(sql_problem.resolved_at.year).to eq(2026)
      expect(sql_problem.resolved_at.month).to eq(7)
      expect(sql_problem.notices_count).to eq(10)
    end

    it "migrates notices with null environment-name" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      mongo_err = create(:err, problem: mongo_problem)
      mongo_backtrace = create(:backtrace, lines: [{"file" => "app.rb", "number" => 1}])
      mongo_notice = create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        server_environment: {"environment-name" => nil, "hostname" => "areprer7"})

      invoke(:all)

      sql_notice = Errbit::Notice.find_by!(bson_id: mongo_notice.id.to_s)
      expect(sql_notice.server_environment["environment-name"]).to be_nil
      expect(sql_notice.server_environment["hostname"]).to eq("areprer7")
    end

    it "migrates backtraces with empty lines" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      mongo_err = create(:err, problem: mongo_problem)
      mongo_backtrace = create(:backtrace, lines: [{"file" => "", "number" => "", "method" => ""}])
      create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        message: "empty backtrace test")

      invoke(:all)

      sql_backtrace = Errbit::Backtrace.find_by!(bson_id: mongo_backtrace.id.to_s)
      expect(sql_backtrace.lines).to eq([{"file" => "", "number" => "", "method" => ""}])
    end

    it "migrates problems with large user agent distributions" do
      mongo_app = create(:app)
      user_agents = {}
      113.times do |i|
        key = "ua-#{i.to_s.rjust(32, '0')}"
        user_agents[key] = {"value" => "Mozilla/5.0 (Test #{i})", "count" => i + 1}
      end
      mongo_problem = create(:problem, app: mongo_app, user_agents: user_agents)

      invoke(:all)

      sql_problem = Errbit::Problem.find_by(bson_id: mongo_problem.id.to_s)
      expect(sql_problem.user_agents.keys.length).to eq(113)
      expect(sql_problem.user_agents.values.map { |v| v["count"] }.max).to eq(113)
    end

    it "migrates multi-line error messages" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      mongo_err = create(:err, problem: mongo_problem)
      mongo_backtrace = create(:backtrace, lines: [{"file" => "app.rb", "number" => 1}])
      multi_line_message = "unsupported key type `ssh-ed25519'\nnet-ssh requires the following gems for ed25519 support:\n * ed25519 (>= 1.2, < 2.0)\n * bcrypt_pbkdf (>= 1.0, < 2.0)\nSee https://github.com/net-ssh/net-ssh/issues/565"
      mongo_notice = create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        message: multi_line_message)

      invoke(:all)

      sql_notice = Errbit::Notice.find_by!(bson_id: mongo_notice.id.to_s)
      expect(sql_notice.message).to include("ssh-ed25519")
      expect(sql_notice.message).to include("net-ssh")
      expect(sql_notice.message).to include("github.com")
    end

    it "migrates apps with empty bitbucket_repo" do
      mongo_app = create(:app, name: "Empty Bitbucket App", bitbucket_repo: "")

      invoke(:all)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      expect(sql_app.bitbucket_repo).to eq("")
    end

    it "migrates base NotificationService with notify_at_notices [0]" do
      mongo_app = create(:app, name: "Base Service Notify Zero")
      App.collection.find_one_and_update(
        {_id: mongo_app.id},
        {"$set" => {
          "notification_service._id" => BSON::ObjectId.new.to_s,
          "notification_service._type" => "NotificationService",
          "notification_service.notify_at_notices" => [0]
        }}
      )

      invoke(:all)

      sql_app = Errbit::App.find_by!(bson_id: mongo_app.id.to_s)
      expect(sql_app.notification_service).to be_a(Errbit::NotificationService)
      expect(sql_app.notification_service.notify_at_notices).to eq([0])
    end

    it "migrates problems with server_environment containing null app-version" do
      mongo_app = create(:app)
      mongo_problem = create(:problem, app: mongo_app)
      mongo_err = create(:err, problem: mongo_problem)
      mongo_backtrace = create(:backtrace, lines: [{"file" => "app.rb", "number" => 1}])
      mongo_notice = create(:notice,
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        server_environment: {"environment-name" => "production-7.2", "app-version" => nil, "hostname" => "areprer7"})

      invoke(:all)

      sql_notice = Errbit::Notice.find_by!(bson_id: mongo_notice.id.to_s)
      expect(sql_notice.server_environment["app-version"]).to be_nil
      expect(sql_notice.server_environment["hostname"]).to eq("areprer7")
    end
  end
end
