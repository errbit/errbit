# frozen_string_literal: true

# Rake tasks for porting MongoDB-backed Errbit data into the new SQL-backed
# Errbit::* models. Each task is idempotent — records are linked back to their
# Mongo origin via the `bson_id` string column, so re-running updates instead
# of duplicating.

namespace :errbit do
  namespace :migrate do
    # ------------------------------------------------------------------
    # Helpers shared by all tasks below
    # ------------------------------------------------------------------
    module Helpers
      module_function

      def ar_id_for(klass, mongo_id)
        return nil if mongo_id.blank?

        klass.where(bson_id: mongo_id.to_s).pick(:id)
      end

      def with_preserved_timestamps(klass)
        klass.record_timestamps = false
        yield
      ensure
        klass.record_timestamps = true
      end

      def assign_and_save!(record, attrs, stats)
        existed = record.persisted?
        # Coerce nil timestamps to now — some Mongoid embedded docs (e.g.
        # auto-built fingerprinters) never get created_at/updated_at set, and
        # the SQL columns are NOT NULL.
        attrs[:created_at] ||= Time.current if attrs.key?(:created_at)
        attrs[:updated_at] ||= attrs[:created_at] || Time.current if attrs.key?(:updated_at)
        record.assign_attributes(attrs)

        if record.save(validate: false)
          existed ? stats[:updated] += 1 : stats[:created] += 1
        else
          stats[:failed] += 1
          warn "  failed bson_id=#{record.bson_id}: #{record.errors.full_messages.join(", ")}"
        end
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::NotNullViolation => e
        stats[:failed] += 1
        warn "  failed bson_id=#{record.bson_id}: #{e.message}"
      end

      def print_summary(label, stats)
        puts "=== Migrated #{label}: #{stats[:created]} created, #{stats[:updated]} updated, #{stats[:failed]} failed."
      end
    end

    # ------------------------------------------------------------------
    # Users
    # ------------------------------------------------------------------
    desc "Migrate users from MongoDB to Errbit::User (SQL). Idempotent — re-runs update by bson_id."
    task users: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::User.transaction do
        Helpers.with_preserved_timestamps(Errbit::User) do
          ::User.all.each do |mongo|
            ar = Errbit::User.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              email: mongo.email.to_s,
              encrypted_password: mongo.encrypted_password.to_s,
              reset_password_token: mongo.reset_password_token,
              reset_password_sent_at: mongo.reset_password_sent_at,
              remember_created_at: mongo.remember_created_at,
              sign_in_count: mongo.sign_in_count || 0,
              current_sign_in_at: mongo.current_sign_in_at,
              last_sign_in_at: mongo.last_sign_in_at,
              current_sign_in_ip: mongo.current_sign_in_ip,
              last_sign_in_ip: mongo.last_sign_in_ip,
              authentication_token: mongo.authentication_token,
              name: mongo.name,
              username: mongo.try(:username),
              admin: mongo.admin || false,
              per_page: mongo.per_page || Errbit::User::PER_PAGE,
              time_zone: mongo.time_zone || "UTC",
              github_login: mongo.github_login,
              github_oauth_token: mongo.github_oauth_token,
              google_uid: mongo.google_uid,
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("users", stats)
    end

    # ------------------------------------------------------------------
    # SiteConfig (singleton)
    # ------------------------------------------------------------------
    desc "Migrate SiteConfig from MongoDB to Errbit::SiteConfig (SQL)."
    task site_configs: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::SiteConfig.transaction do
        Helpers.with_preserved_timestamps(Errbit::SiteConfig) do
          ::SiteConfig.all.each do |mongo|
            ar = Errbit::SiteConfig.find_or_initialize_by(bson_id: mongo._id.to_s)
            fp = mongo.notice_fingerprinter

            Helpers.assign_and_save!(ar, {
              error_class: fp&.error_class.nil? ? true : fp.error_class,
              message: fp&.message.nil? ? true : fp.message,
              backtrace_lines: fp&.backtrace_lines || -1,
              component: fp&.component.nil? ? true : fp.component,
              action: fp&.action.nil? ? true : fp.action,
              environment_name: fp&.environment_name.nil? ? true : fp.environment_name,
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("site_configs", stats)
    end

    # ------------------------------------------------------------------
    # Apps
    # ------------------------------------------------------------------
    desc "Migrate Apps from MongoDB to Errbit::App (SQL)."
    task apps: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::App.transaction do
        Helpers.with_preserved_timestamps(Errbit::App) do
          ::App.all.each do |mongo|
            ar = Errbit::App.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              name: mongo.name,
              api_key: mongo.api_key,
              github_repo: mongo.github_repo,
              bitbucket_repo: mongo.bitbucket_repo,
              custom_backtrace_url_template: mongo.try(:custom_backtrace_url_template),
              asset_host: mongo.asset_host,
              repository_branch: mongo.repository_branch,
              current_app_version: mongo.current_app_version,
              notify_all_users: mongo.notify_all_users || false,
              notify_on_errs: mongo.notify_on_errs.nil? ? true : mongo.notify_on_errs,
              # Read via attributes hash to bypass the App#email_at_notices
              # getter override which masks the stored value behind the global
              # Errbit::Config.email_at_notices when per_app_email_at_notices
              # is off.
              email_at_notices: mongo.attributes["email_at_notices"] || [],
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("apps", stats)
    end

    # ------------------------------------------------------------------
    # Watchers (embedded in App)
    # ------------------------------------------------------------------
    desc "Migrate embedded App watchers to Errbit::Watcher (SQL). Run after :users and :apps."
    task watchers: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::Watcher.transaction do
        Helpers.with_preserved_timestamps(Errbit::Watcher) do
          ::App.all.each do |mongo_app|
            errbit_app_id = Helpers.ar_id_for(Errbit::App, mongo_app._id)
            next unless errbit_app_id

            mongo_app.watchers.each do |mongo_watcher|
              ar = Errbit::Watcher.find_or_initialize_by(bson_id: mongo_watcher._id.to_s)

              Helpers.assign_and_save!(ar, {
                errbit_app_id: errbit_app_id,
                errbit_user_id: Helpers.ar_id_for(Errbit::User, mongo_watcher.user_id),
                email: mongo_watcher.email,
                created_at: mongo_watcher.try(:created_at),
                updated_at: mongo_watcher.try(:updated_at)
              }, stats)
            end
          end
        end
      end

      Helpers.print_summary("watchers", stats)
    end

    # ------------------------------------------------------------------
    # IssueTrackers (embedded in App)
    # ------------------------------------------------------------------
    desc "Migrate embedded App issue trackers to Errbit::IssueTracker (SQL). Run after :apps."
    task issue_trackers: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::IssueTracker.transaction do
        Helpers.with_preserved_timestamps(Errbit::IssueTracker) do
          ::App.all.each do |mongo_app|
            mongo_tracker = mongo_app.issue_tracker
            next if mongo_tracker.blank?

            errbit_app_id = Helpers.ar_id_for(Errbit::App, mongo_app._id)
            next unless errbit_app_id

            ar = Errbit::IssueTracker.find_or_initialize_by(bson_id: mongo_tracker._id.to_s)

            Helpers.assign_and_save!(ar, {
              errbit_app_id: errbit_app_id,
              type_tracker: mongo_tracker.attributes["type_tracker"],
              options: mongo_tracker.options || {},
              created_at: mongo_tracker.try(:created_at),
              updated_at: mongo_tracker.try(:updated_at)
            }, stats)
          end
        end
      end

      Helpers.print_summary("issue_trackers", stats)
    end

    # ------------------------------------------------------------------
    # NotificationServices (embedded in App, polymorphic via Mongoid _type)
    # ------------------------------------------------------------------
    desc "Migrate embedded App notification services to Errbit::NotificationService (SQL STI). Run after :apps."
    task notification_services: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::NotificationService.transaction do
        Helpers.with_preserved_timestamps(Errbit::NotificationService) do
          ::App.all.each do |mongo_app|
            mongo_ns = mongo_app.notification_service
            next if mongo_ns.blank?

            errbit_app_id = Helpers.ar_id_for(Errbit::App, mongo_app._id)
            next unless errbit_app_id

            ar_type = "Errbit::#{mongo_ns.class.name}"

            ar = Errbit::NotificationService.find_or_initialize_by(bson_id: mongo_ns._id.to_s)
            ar = ar.becomes!(ar_type.constantize)

            Helpers.assign_and_save!(ar, {
              errbit_app_id: errbit_app_id,
              room_id: mongo_ns.try(:room_id),
              mentions: mongo_ns.try(:mentions),
              user_id: mongo_ns.try(:user_id),
              service_url: mongo_ns.try(:service_url),
              service: mongo_ns.try(:service),
              api_token: mongo_ns.try(:api_token),
              subdomain: mongo_ns.try(:subdomain),
              sender_name: mongo_ns.try(:sender_name),
              notify_at_notices: mongo_ns.try(:notify_at_notices) || [],
              created_at: mongo_ns.try(:created_at),
              updated_at: mongo_ns.try(:updated_at)
            }, stats)
          end
        end
      end

      Helpers.print_summary("notification_services", stats)
    end

    # ------------------------------------------------------------------
    # NoticeFingerprinters (embedded in App)
    # ------------------------------------------------------------------
    desc "Migrate embedded App notice fingerprinters to Errbit::NoticeFingerprinter (SQL). Run after :apps."
    task notice_fingerprinters: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::NoticeFingerprinter.transaction do
        Helpers.with_preserved_timestamps(Errbit::NoticeFingerprinter) do
          ::App.all.each do |mongo_app|
            mongo_fp = mongo_app.notice_fingerprinter
            next if mongo_fp.blank?

            errbit_app_id = Helpers.ar_id_for(Errbit::App, mongo_app._id)
            next unless errbit_app_id

            ar = Errbit::NoticeFingerprinter.find_or_initialize_by(bson_id: mongo_fp._id.to_s)

            Helpers.assign_and_save!(ar, {
              errbit_app_id: errbit_app_id,
              error_class: mongo_fp.error_class.nil? ? true : mongo_fp.error_class,
              message: mongo_fp.message.nil? ? true : mongo_fp.message,
              backtrace_lines: mongo_fp.backtrace_lines || -1,
              component: mongo_fp.component.nil? ? true : mongo_fp.component,
              action: mongo_fp.action.nil? ? true : mongo_fp.action,
              environment_name: mongo_fp.environment_name.nil? ? true : mongo_fp.environment_name,
              source: mongo_fp.source,
              created_at: mongo_fp.try(:created_at),
              updated_at: mongo_fp.try(:updated_at)
            }, stats)
          end
        end
      end

      Helpers.print_summary("notice_fingerprinters", stats)
    end

    # ------------------------------------------------------------------
    # Backtraces (standalone)
    # ------------------------------------------------------------------
    desc "Migrate Backtraces from MongoDB to Errbit::Backtrace (SQL)."
    task backtraces: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::Backtrace.transaction do
        Helpers.with_preserved_timestamps(Errbit::Backtrace) do
          ::Backtrace.all.each do |mongo|
            ar = Errbit::Backtrace.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              fingerprint: mongo.fingerprint,
              lines: mongo.lines || [],
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("backtraces", stats)
    end

    # ------------------------------------------------------------------
    # Problems (depends on App)
    # ------------------------------------------------------------------
    desc "Migrate Problems from MongoDB to Errbit::Problem (SQL). Run after :apps."
    task problems: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::Problem.transaction do
        Helpers.with_preserved_timestamps(Errbit::Problem) do
          ::Problem.all.each do |mongo|
            errbit_app_id = Helpers.ar_id_for(Errbit::App, mongo.app_id)
            unless errbit_app_id
              stats[:failed] += 1
              warn "  failed problem bson_id=#{mongo._id}: app not migrated"
              next
            end

            ar = Errbit::Problem.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              errbit_app_id: errbit_app_id,
              first_notice_at: mongo.first_notice_at,
              last_notice_at: mongo.last_notice_at,
              resolved: mongo.resolved || false,
              resolved_at: mongo.resolved_at,
              issue_link: mongo.issue_link,
              issue_type: mongo[:issue_type],
              app_name: mongo.app_name,
              notices_count: mongo.notices_count || 0,
              comments_count: mongo.comments_count || 0,
              message: mongo.message,
              environment: mongo.environment,
              error_class: mongo.error_class,
              where: mongo.where,
              user_agents: mongo.user_agents || {},
              messages: mongo.messages || {},
              hosts: mongo.hosts || {},
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("problems", stats)
    end

    # ------------------------------------------------------------------
    # Errs (depends on Problem)
    # ------------------------------------------------------------------
    desc "Migrate Errs from MongoDB to Errbit::Err (SQL). Run after :problems."
    task errs: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::Err.transaction do
        Helpers.with_preserved_timestamps(Errbit::Err) do
          ::Err.all.each do |mongo|
            errbit_problem_id = Helpers.ar_id_for(Errbit::Problem, mongo.problem_id)
            unless errbit_problem_id
              stats[:failed] += 1
              warn "  failed err bson_id=#{mongo._id}: problem not migrated"
              next
            end

            ar = Errbit::Err.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              errbit_problem_id: errbit_problem_id,
              fingerprint: mongo.fingerprint,
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("errs", stats)
    end

    # ------------------------------------------------------------------
    # Notices (depends on App + Err + Backtrace)
    # ------------------------------------------------------------------
    desc "Migrate Notices from MongoDB to Errbit::Notice (SQL). Run after :apps, :errs, :backtraces."
    task notices: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::Notice.transaction do
        Helpers.with_preserved_timestamps(Errbit::Notice) do
          ::Notice.all.each do |mongo|
            errbit_app_id = Helpers.ar_id_for(Errbit::App, mongo.app_id)
            errbit_err_id = Helpers.ar_id_for(Errbit::Err, mongo.err_id)
            errbit_backtrace_id = Helpers.ar_id_for(Errbit::Backtrace, mongo.backtrace_id)

            unless errbit_app_id && errbit_err_id && errbit_backtrace_id
              stats[:failed] += 1
              warn "  failed notice bson_id=#{mongo._id}: missing app/err/backtrace mapping"
              next
            end

            ar = Errbit::Notice.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              errbit_app_id: errbit_app_id,
              errbit_err_id: errbit_err_id,
              errbit_backtrace_id: errbit_backtrace_id,
              message: mongo.message,
              framework: mongo.framework,
              error_class: mongo.error_class,
              server_environment: mongo.server_environment,
              request: mongo.request,
              notifier: mongo.notifier,
              user_attributes: mongo.try(:user_attributes),
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("notices", stats)
    end

    # ------------------------------------------------------------------
    # Comments (depends on Problem + User)
    # ------------------------------------------------------------------
    desc "Migrate Comments from MongoDB to Errbit::Comment (SQL). Run after :problems and :users."
    task comments: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::Comment.transaction do
        Helpers.with_preserved_timestamps(Errbit::Comment) do
          ::Comment.all.each do |mongo|
            errbit_problem_id = Helpers.ar_id_for(Errbit::Problem, mongo.err_id)
            errbit_user_id = Helpers.ar_id_for(Errbit::User, mongo.user_id)

            unless errbit_problem_id && errbit_user_id
              stats[:failed] += 1
              warn "  failed comment bson_id=#{mongo._id}: missing problem/user mapping"
              next
            end

            ar = Errbit::Comment.find_or_initialize_by(bson_id: mongo._id.to_s)

            Helpers.assign_and_save!(ar, {
              errbit_problem_id: errbit_problem_id,
              errbit_user_id: errbit_user_id,
              body: mongo.body,
              created_at: mongo.created_at,
              updated_at: mongo.updated_at
            }, stats)
          end
        end
      end

      Helpers.print_summary("comments", stats)
    end

    # ------------------------------------------------------------------
    # All — runs every model migration in dependency order
    # ------------------------------------------------------------------
    desc "Run all Mongo→SQL migrations in dependency order."
    task all: :environment do
      %i[
        users
        site_configs
        apps
        watchers
        issue_trackers
        notification_services
        notice_fingerprinters
        backtraces
        problems
        errs
        notices
        comments
      ].each do |t|
        task = Rake::Task["errbit:migrate:#{t}"]
        task.reenable
        task.invoke
      end
    end
  end
end
