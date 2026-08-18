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
  end
end
