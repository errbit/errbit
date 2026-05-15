# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "errbit:migrate" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def invoke(task_name)
    Rake::Task["errbit:migrate:#{task_name}"].reenable
    Rake::Task["errbit:migrate:#{task_name}"].invoke
  end

  describe ":users" do
    it "creates an Errbit::User row for each Mongo User, linked by bson_id" do
      mongo_user = User.create!(
        email: "ported@example.com",
        name: "Ported",
        admin: true,
        password: "secret-password",
        password_confirmation: "secret-password"
      )

      expect { invoke(:users) }.to change(Errbit::User, :count).by(1)

      ar_user = Errbit::User.find_by!(bson_id: mongo_user._id.to_s)
      expect(ar_user.email).to eq("ported@example.com")
      expect(ar_user.name).to eq("Ported")
      expect(ar_user.admin).to eq(true)
      expect(ar_user.encrypted_password).to eq(mongo_user.encrypted_password)
      expect(ar_user.authentication_token).to eq(mongo_user.authentication_token)
    end

    it "preserves the original Mongo timestamps" do
      created = 3.years.ago.change(usec: 0)
      updated = 1.year.ago.change(usec: 0)

      mongo_user = User.create!(email: "old@example.com", name: "Old", password: "secret-password")
      mongo_user.update_attributes!(created_at: created, updated_at: updated)

      invoke(:users)

      ar_user = Errbit::User.find_by!(bson_id: mongo_user._id.to_s)
      expect(ar_user.created_at.to_i).to eq(created.to_i)
      expect(ar_user.updated_at.to_i).to eq(updated.to_i)
    end

    it "is idempotent — re-running updates the existing record" do
      mongo_user = User.create!(email: "twice@example.com", name: "Twice", password: "secret-password")

      invoke(:users)
      mongo_user.update!(name: "Renamed")

      expect { invoke(:users) }.not_to change(Errbit::User, :count)
      expect(Errbit::User.find_by!(bson_id: mongo_user._id.to_s).name).to eq("Renamed")
    end

    it "skips devise validations so users without passwords still migrate" do
      mongo_user = User.new(email: "gh@example.com", name: "GH", github_login: "gh-handle")
      mongo_user.save(validate: false)

      expect { invoke(:users) }.to change(Errbit::User, :count).by(1)
      expect(Errbit::User.find_by!(bson_id: mongo_user._id.to_s).github_login).to eq("gh-handle")
    end
  end

  describe ":apps" do
    it "creates an Errbit::App row linked by bson_id" do
      mongo_app = App.create!(name: "Mongo App", github_repo: "owner/repo", repository_branch: "main")

      expect { invoke(:apps) }.to change(Errbit::App, :count).by(1)

      ar = Errbit::App.find_by!(bson_id: mongo_app._id.to_s)
      expect(ar.name).to eq("Mongo App")
      expect(ar.github_repo).to eq("owner/repo")
      expect(ar.repository_branch).to eq("main")
      expect(ar.api_key).to eq(mongo_app.api_key)
    end

    it "preserves email_at_notices in the underlying column" do
      mongo_app = App.create!(name: "Notif App", email_at_notices: [1, 5, 10])

      invoke(:apps)

      # The Errbit::App#email_at_notices getter masks the column value when
      # per_app_email_at_notices is off, so read the deserialized column directly.
      ar = Errbit::App.find_by!(bson_id: mongo_app._id.to_s)
      expect(ar.attributes["email_at_notices"]).to eq([1, 5, 10])
    end
  end

  describe ":site_configs" do
    it "creates an Errbit::SiteConfig with fingerprinter fields flattened" do
      Errbit::SiteConfig.delete_all
      SiteConfig.delete_all

      mongo = SiteConfig.new
      mongo.build_notice_fingerprinter(error_class: false, backtrace_lines: 3)
      mongo.save!

      expect { invoke(:site_configs) }.to change(Errbit::SiteConfig, :count).by(1)

      ar = Errbit::SiteConfig.find_by!(bson_id: mongo._id.to_s)
      expect(ar.error_class).to eq(false)
      expect(ar.backtrace_lines).to eq(3)
    end
  end

  describe ":watchers" do
    it "migrates embedded watchers and resolves user references via bson_id" do
      mongo_user = User.create!(email: "watcher@example.com", name: "Watcher", password: "secret-password")
      mongo_app = App.create!(name: "Watched")
      mongo_app.watchers.create!(user_id: mongo_user._id)
      mongo_app.watchers.create!(email: "external@example.com")

      invoke(:users)
      invoke(:apps)
      expect { invoke(:watchers) }.to change(Errbit::Watcher, :count).by(2)

      errbit_app = Errbit::App.find_by!(bson_id: mongo_app._id.to_s)
      errbit_user = Errbit::User.find_by!(bson_id: mongo_user._id.to_s)

      addresses = errbit_app.watchers.reload.map(&:address)
      expect(addresses).to match_array(["watcher@example.com", "external@example.com"])
      expect(errbit_app.watchers.find_by(email: nil).user).to eq(errbit_user)
    end
  end

  describe ":issue_trackers" do
    it "migrates the embedded IssueTracker linked to its app" do
      mongo_app = App.new(name: "Tracker App")
      mongo_app.build_issue_tracker(type_tracker: "mock", options: {"foo" => "1"})
      mongo_app.save!

      invoke(:apps)
      expect { invoke(:issue_trackers) }.to change(Errbit::IssueTracker, :count).by(1)

      errbit_app = Errbit::App.find_by!(bson_id: mongo_app._id.to_s)
      tracker = errbit_app.reload.issue_tracker
      expect(tracker.type_tracker).to eq("mock")
      expect(tracker.options["foo"]).to eq("1")
    end
  end

  describe ":notification_services" do
    it "migrates an embedded slack service and preserves STI type" do
      mongo_app = App.new(name: "Slack App")
      mongo_app.build_notification_service(
        _type: "NotificationServices::SlackService",
        service_url: "https://hooks.slack.com/services/X",
        room_id: "#errors"
      )
      mongo_app.save!

      invoke(:apps)
      expect { invoke(:notification_services) }.to change(Errbit::NotificationService, :count).by(1)

      ar = Errbit::App.find_by!(bson_id: mongo_app._id.to_s).reload.notification_service
      expect(ar).to be_a(Errbit::NotificationServices::SlackService)
      expect(ar.service_url).to eq("https://hooks.slack.com/services/X")
      expect(ar.room_id).to eq("#errors")
    end
  end

  describe ":notice_fingerprinters" do
    it "migrates an embedded fingerprinter linked to its app" do
      mongo_app = App.create!(name: "FP App")
      mongo_app.notice_fingerprinter.update!(message: false, backtrace_lines: 5, source: "site")

      invoke(:apps)
      expect { invoke(:notice_fingerprinters) }.to change(Errbit::NoticeFingerprinter, :count).by(1)

      ar = Errbit::App.find_by!(bson_id: mongo_app._id.to_s).reload.notice_fingerprinter
      expect(ar.message).to eq(false)
      expect(ar.backtrace_lines).to eq(5)
      expect(ar.source).to eq("site")
    end
  end

  describe ":backtraces" do
    it "creates an Errbit::Backtrace row linked by bson_id" do
      mongo = Backtrace.create!(
        fingerprint: "abc123",
        lines: [{"number" => "1", "file" => "x.rb", "method" => "foo"}]
      )

      expect { invoke(:backtraces) }.to change(Errbit::Backtrace, :count).by(1)

      ar = Errbit::Backtrace.find_by!(bson_id: mongo._id.to_s)
      expect(ar.fingerprint).to eq("abc123")
      expect(ar.lines.first["file"]).to eq("x.rb")
    end
  end

  describe ":problems" do
    it "creates an Errbit::Problem linked to its app via bson_id" do
      mongo_app = App.create!(name: "Problem App")
      mongo = Problem.create!(
        app: mongo_app,
        environment: "production",
        error_class: "RuntimeError",
        message: "boom"
      )

      invoke(:apps)
      expect { invoke(:problems) }.to change(Errbit::Problem, :count).by(1)

      ar = Errbit::Problem.find_by!(bson_id: mongo._id.to_s)
      expect(ar.app).to eq(Errbit::App.find_by!(bson_id: mongo_app._id.to_s))
      expect(ar.environment).to eq("production")
      expect(ar.error_class).to eq("RuntimeError")
    end

    it "skips problems whose app hasn't been migrated yet" do
      App.create!(name: "Skipped App").tap do |a|
        Problem.create!(app: a, environment: "production", error_class: "X")
      end

      expect { invoke(:problems) }.not_to change(Errbit::Problem, :count)
    end
  end

  describe ":errs" do
    it "creates an Errbit::Err linked to its problem via bson_id" do
      mongo_app = App.create!(name: "Err App")
      mongo_problem = Problem.create!(app: mongo_app, environment: "production", error_class: "X")
      mongo_err = Err.create!(problem: mongo_problem, fingerprint: "fp-1")

      invoke(:apps)
      invoke(:problems)
      expect { invoke(:errs) }.to change(Errbit::Err, :count).by(1)

      ar = Errbit::Err.find_by!(bson_id: mongo_err._id.to_s)
      expect(ar.fingerprint).to eq("fp-1")
      expect(ar.problem).to eq(Errbit::Problem.find_by!(bson_id: mongo_problem._id.to_s))
    end
  end

  describe ":notices" do
    it "creates an Errbit::Notice linked to app, err, and backtrace via bson_id" do
      mongo_app = App.create!(name: "Notice App")
      mongo_problem = Problem.create!(app: mongo_app, environment: "production", error_class: "X")
      mongo_err = Err.create!(problem: mongo_problem, fingerprint: "n-fp")
      mongo_backtrace = Backtrace.create!(fingerprint: "bt-fp", lines: [{"f" => "a.rb"}])
      mongo_notice = Notice.create!(
        app: mongo_app,
        err: mongo_err,
        backtrace: mongo_backtrace,
        message: "Notice msg",
        server_environment: {"environment-name" => "production"},
        notifier: {"name" => "Notifier"}
      )

      invoke(:apps)
      invoke(:backtraces)
      invoke(:problems)
      invoke(:errs)
      expect { invoke(:notices) }.to change(Errbit::Notice, :count).by(1)

      ar = Errbit::Notice.find_by!(bson_id: mongo_notice._id.to_s)
      expect(ar.message).to eq("Notice msg")
      expect(ar.app).to eq(Errbit::App.find_by!(bson_id: mongo_app._id.to_s))
      expect(ar.err).to eq(Errbit::Err.find_by!(bson_id: mongo_err._id.to_s))
      expect(ar.backtrace).to eq(Errbit::Backtrace.find_by!(bson_id: mongo_backtrace._id.to_s))
    end
  end

  describe ":comments" do
    it "creates an Errbit::Comment linked to its problem and user via bson_id" do
      mongo_user = User.create!(email: "c@example.com", name: "Commenter", password: "secret-password")
      mongo_app = App.create!(name: "Comment App")
      mongo_problem = Problem.create!(app: mongo_app, environment: "production", error_class: "X")
      mongo_comment = Comment.create!(err: mongo_problem, user: mongo_user, body: "first comment")

      invoke(:users)
      invoke(:apps)
      invoke(:problems)
      expect { invoke(:comments) }.to change(Errbit::Comment, :count).by(1)

      ar = Errbit::Comment.find_by!(bson_id: mongo_comment._id.to_s)
      expect(ar.body).to eq("first comment")
      expect(ar.err).to eq(Errbit::Problem.find_by!(bson_id: mongo_problem._id.to_s))
      expect(ar.user).to eq(Errbit::User.find_by!(bson_id: mongo_user._id.to_s))
    end
  end

  describe ":all" do
    it "runs every migration in dependency order with one Rake invocation" do
      mongo_user = User.create!(email: "all@example.com", name: "All", password: "secret-password")
      mongo_app = App.create!(name: "All App")
      mongo_problem = Problem.create!(app: mongo_app, environment: "production", error_class: "X")
      mongo_err = Err.create!(problem: mongo_problem, fingerprint: "all-fp")
      mongo_backtrace = Backtrace.create!(fingerprint: "all-bt", lines: [])
      Notice.create!(app: mongo_app, err: mongo_err, backtrace: mongo_backtrace,
        server_environment: {"environment-name" => "production"},
        notifier: {"name" => "Notifier"})
      Comment.create!(err: mongo_problem, user: mongo_user, body: "all-comment")

      invoke(:all)

      expect(Errbit::User.where(bson_id: mongo_user._id.to_s)).to exist
      expect(Errbit::App.where(bson_id: mongo_app._id.to_s)).to exist
      expect(Errbit::Problem.where(bson_id: mongo_problem._id.to_s)).to exist
      expect(Errbit::Err.where(bson_id: mongo_err._id.to_s)).to exist
      expect(Errbit::Backtrace.where(bson_id: mongo_backtrace._id.to_s)).to exist
      expect(Errbit::Notice.count).to be >= 1
      expect(Errbit::Comment.count).to be >= 1
    end
  end
end
