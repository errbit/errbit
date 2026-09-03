# frozen_string_literal: true

module Errbit
  module MigrateHelpers
    BATCH_SIZE = Integer(ENV.fetch("ERRBIT_MIGRATE_BATCH_SIZE", 1000))

    module_function

    def each_mongo(criteria)
      return enum_for(__method__, criteria) unless block_given?

      criteria = criteria.no_timeout if criteria.respond_to?(:no_timeout)
      criteria = criteria.batch_size(BATCH_SIZE) if criteria.respond_to?(:batch_size)
      criteria.each { |record| yield record }
    end

    def each_mongo_batch(criteria)
      each_mongo(criteria).each_slice(BATCH_SIZE) do |records|
        Errbit::ApplicationRecord.transaction { records.each { |record| yield record } }
      end
    end

    def with_import_mode
      previous = Errbit.migrating?
      Errbit.migrating = true
      yield
    ensure
      Errbit.migrating = previous
    end

    def ar_id_for(klass, mongo_id)
      return nil if mongo_id.blank?

      sql_ids_for(klass)[mongo_id.to_s]
    end

    def sql_ids_for(klass)
      @sql_ids ||= {}
      @sql_ids[klass] ||= klass.where.not(bson_id: nil).pluck(:bson_id, :id).to_h
    end

    def reset_sql_ids!
      @sql_ids = {}
    end

    def cutover_marker
      Rails.root.join("storage", ".mongo_to_sql_migrated")
    end

    def normalize_hash(value)
      return value unless value.respond_to?(:to_json)

      ActiveSupport::JSON.decode(value.to_json)
    end

    def with_preserved_timestamps(klass)
      previous = klass.record_timestamps
      klass.record_timestamps = false
      yield
    ensure
      klass.record_timestamps = previous
    end

    def assign_and_save!(record, attrs, stats)
      existed = record.persisted?
      attrs[:created_at] ||= Time.current if attrs.key?(:created_at)
      attrs[:updated_at] ||= attrs[:created_at] || Time.current if attrs.key?(:updated_at)
      record.assign_attributes(attrs)
      with_import_mode { record.save!(validate: false) }
      existed ? stats[:updated] += 1 : stats[:created] += 1
    rescue => e
      stats[:failed] += 1
      warn "  failed #{record.class.name} bson_id=#{record.bson_id.inspect}: #{e.message}"
    end

    def print_summary(label, stats)
      puts "=== Migrated #{label}: #{stats[:created]} created, #{stats[:updated]} updated, #{stats[:failed]} failed."
      raise "MongoDB to SQL migration failed for #{label} with #{stats[:failed]} failed row(s)." if stats[:failed] > 0
    end

    def stats
      {created: 0, updated: 0, failed: 0}
    end

    def verify_stats
      {checked: 0, failed: 0}
    end

    def verify_count(label, mongo_count, sql_count, stats)
      stats[:checked] += 1
      return if mongo_count == sql_count

      stats[:failed] += 1
      warn "  failed #{label}: Mongo has #{mongo_count}, SQL has #{sql_count}"
    end

    def verify_mapping(label, mongo_id, stats)
      stats[:checked] += 1
      return if yield

      stats[:failed] += 1
      warn "  failed #{label} bson_id=#{mongo_id}: missing SQL relationship mapping"
    end

    def verify_problem_state(mongo, sql, stats)
      state = {
        first_notice_at: mongo.first_notice_at,
        last_notice_at: mongo.last_notice_at,
        resolved: mongo.resolved || false,
        resolved_at: mongo.resolved_at,
        notices_count: mongo.notices_count || 0,
        comments_count: mongo.comments_count || 0,
        messages: normalize_hash(mongo.messages || {}),
        hosts: normalize_hash(mongo.hosts || {}),
        user_agents: normalize_hash(mongo.user_agents || {})
      }

      state.each do |attribute, mongo_value|
        stats[:checked] += 1
        next if sql.public_send(attribute) == mongo_value

        stats[:failed] += 1
        warn "  failed problem state bson_id=#{mongo.id} #{attribute}: Mongo #{mongo_value.inspect}, SQL #{sql.public_send(attribute).inspect}"
      end
    end

    def print_verification_summary(stats)
      puts "=== Verified MongoDB to SQL migration: #{stats[:checked]} checks, #{stats[:failed]} failed."
      raise "MongoDB to SQL migration verification failed with #{stats[:failed]} issue(s)." if stats[:failed] > 0
    end
  end
end

namespace :errbit do
  namespace :migrate do
    desc "Migrate users from MongoDB to SQL. Idempotent by bson_id."
    task users: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::User) do
        Errbit::MigrateHelpers.each_mongo_batch(::User.all) do |mongo|
          ar = Errbit::User.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
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

      Errbit::MigrateHelpers.print_summary("users", stats)
    end

    desc "Migrate SiteConfig from MongoDB to SQL."
    task site_configs: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::SiteConfig) do
        Errbit::MigrateHelpers.each_mongo_batch(::SiteConfig.all) do |mongo|
          ar = Errbit::SiteConfig.find_or_initialize_by(bson_id: mongo.id.to_s)
          fp = mongo.notice_fingerprinter
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            error_class: fp&.error_class.nil? || fp.error_class,
            message: fp&.message.nil? || fp.message,
            backtrace_lines: fp&.backtrace_lines || -1,
            component: fp&.component.nil? || fp.component,
            action: fp&.action.nil? || fp.action,
            environment_name: fp&.environment_name.nil? || fp.environment_name,
            created_at: mongo.created_at,
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("site configs", stats)
    end

    desc "Migrate apps from MongoDB to SQL."
    task apps: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::App) do
        Errbit::MigrateHelpers.each_mongo_batch(::App.all) do |mongo|
          ar = Errbit::App.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            name: mongo.name,
            api_key: mongo.api_key,
            github_repo: mongo.github_repo,
            bitbucket_repo: mongo.bitbucket_repo,
            custom_backtrace_url_template: mongo.try(:custom_backtrace_url_template),
            asset_host: mongo.asset_host,
            repository_branch: mongo.repository_branch,
            current_app_version: mongo.current_app_version,
            notify_all_users: mongo.notify_all_users || false,
            notify_on_errs: mongo.notify_on_errs.nil? || mongo.notify_on_errs,
            email_at_notices: mongo.attributes["email_at_notices"] || [],
            created_at: mongo.created_at,
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("apps", stats)
    end

    desc "Migrate embedded app watchers to SQL. Run after users and apps."
    task watchers: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::Watcher) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::App.all) do |mongo_app|
          app_id = Errbit::MigrateHelpers.ar_id_for(Errbit::App, mongo_app.id)
          next unless app_id

          mongo_app.watchers.each do |mongo|
            ar = Errbit::Watcher.find_or_initialize_by(bson_id: mongo.id.to_s)
            Errbit::MigrateHelpers.assign_and_save!(ar, {
              errbit_app_id: app_id,
              errbit_user_id: Errbit::MigrateHelpers.ar_id_for(Errbit::User, mongo.user_id),
              email: mongo.email,
              created_at: mongo.try(:created_at),
              updated_at: mongo.try(:updated_at)
            }, stats)
          end
        end
      end

      Errbit::MigrateHelpers.print_summary("watchers", stats)
    end

    desc "Migrate embedded app issue trackers to SQL. Run after apps."
    task issue_trackers: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::IssueTracker) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::App.all) do |mongo_app|
          mongo = mongo_app.issue_tracker
          next if mongo.blank?

          app_id = Errbit::MigrateHelpers.ar_id_for(Errbit::App, mongo_app.id)
          next unless app_id

          ar = Errbit::IssueTracker.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            errbit_app_id: app_id,
            type_tracker: mongo.type_tracker,
            options: Errbit::MigrateHelpers.normalize_hash(mongo.options || {}),
            created_at: mongo.try(:created_at),
            updated_at: mongo.try(:updated_at)
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("issue trackers", stats)
    end

    desc "Migrate embedded app notification services to SQL. Run after apps."
    task notification_services: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::NotificationService) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::App.all) do |mongo_app|
          mongo = mongo_app.notification_service
          next if mongo.blank?

          app_id = Errbit::MigrateHelpers.ar_id_for(Errbit::App, mongo_app.id)
          next unless app_id

          ar_type = "Errbit::#{mongo.class.name}".safe_constantize || Errbit::NotificationService
          ar = Errbit::NotificationService.find_or_initialize_by(bson_id: mongo.id.to_s).becomes!(ar_type)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            type: ar_type.name,
            errbit_app_id: app_id,
            room_id: mongo.try(:room_id),
            mentions: mongo.try(:mentions),
            user_id: mongo.try(:user_id),
            service_url: mongo.try(:service_url),
            service: mongo.try(:service),
            api_token: mongo.try(:api_token),
            subdomain: mongo.try(:subdomain),
            sender_name: mongo.try(:sender_name),
            notify_at_notices: mongo.try(:notify_at_notices) || [],
            created_at: mongo.try(:created_at),
            updated_at: mongo.try(:updated_at)
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("notification services", stats)
    end

    desc "Migrate embedded app notice fingerprinters to SQL. Run after apps."
    task notice_fingerprinters: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::NoticeFingerprinter) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::App.all) do |mongo_app|
          mongo = mongo_app.notice_fingerprinter
          next if mongo.blank?

          app_id = Errbit::MigrateHelpers.ar_id_for(Errbit::App, mongo_app.id)
          next unless app_id

          ar = Errbit::NoticeFingerprinter.find_or_initialize_by(errbit_app_id: app_id)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            bson_id: mongo.id.to_s,
            errbit_app_id: app_id,
            error_class: mongo.error_class.nil? || mongo.error_class,
            message: mongo.message.nil? || mongo.message,
            backtrace_lines: mongo.backtrace_lines || -1,
            component: mongo.component.nil? || mongo.component,
            action: mongo.action.nil? || mongo.action,
            environment_name: mongo.environment_name.nil? || mongo.environment_name,
            source: mongo.source,
            created_at: mongo.try(:created_at),
            updated_at: mongo.try(:updated_at)
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("notice fingerprinters", stats)
    end

    desc "Migrate backtraces from MongoDB to SQL."
    task backtraces: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::Backtrace) do
        Errbit::MigrateHelpers.each_mongo_batch(::Backtrace.all) do |mongo|
          ar = Errbit::Backtrace.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            fingerprint: mongo.fingerprint,
            lines: Errbit::MigrateHelpers.normalize_hash(mongo.lines || []),
            created_at: mongo.created_at,
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("backtraces", stats)
    end

    desc "Migrate problems from MongoDB to SQL. Run after apps."
    task problems: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::Problem) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::Problem.all) do |mongo|
          app_id = Errbit::MigrateHelpers.ar_id_for(Errbit::App, mongo.app_id)
          unless app_id
            stats[:failed] += 1
            warn "  failed problem bson_id=#{mongo.id}: app not migrated"
            next
          end

          ar = Errbit::Problem.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            errbit_app_id: app_id,
            first_notice_at: mongo.first_notice_at,
            last_notice_at: mongo.last_notice_at,
            resolved: mongo.resolved || false,
            resolved_at: mongo.resolved_at,
            issue_link: mongo.issue_link,
            issue_type: mongo.issue_type,
            app_name: mongo.app_name,
            notices_count: mongo.notices_count || 0,
            comments_count: mongo.comments_count || 0,
            message: mongo.message,
            environment: mongo.environment,
            error_class: mongo.error_class,
            where: mongo.where,
            user_agents: Errbit::MigrateHelpers.normalize_hash(mongo.user_agents || {}),
            messages: Errbit::MigrateHelpers.normalize_hash(mongo.messages || {}),
            hosts: Errbit::MigrateHelpers.normalize_hash(mongo.hosts || {}),
            created_at: mongo.created_at,
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("problems", stats)
    end

    desc "Migrate errs from MongoDB to SQL. Run after problems."
    task errs: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::Err) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::Err.all) do |mongo|
          problem_id = Errbit::MigrateHelpers.ar_id_for(Errbit::Problem, mongo.problem_id)
          unless problem_id
            stats[:failed] += 1
            warn "  failed err bson_id=#{mongo.id}: problem not migrated"
            next
          end

          ar = Errbit::Err.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            errbit_problem_id: problem_id,
            fingerprint: mongo.fingerprint,
            created_at: mongo.created_at,
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("errs", stats)
    end

    desc "Migrate notices from MongoDB to SQL. Run after apps, errs, and backtraces."
    task notices: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::Notice) do
        Errbit::MigrateHelpers.reset_sql_ids!
        Errbit::MigrateHelpers.each_mongo_batch(::Notice.all) do |mongo|
          app_id = Errbit::MigrateHelpers.ar_id_for(Errbit::App, mongo.app_id)
          err_id = Errbit::MigrateHelpers.ar_id_for(Errbit::Err, mongo.err_id)
          backtrace_id = Errbit::MigrateHelpers.ar_id_for(Errbit::Backtrace, mongo.backtrace_id)

          unless app_id && err_id && backtrace_id
            stats[:failed] += 1
            warn "  failed notice bson_id=#{mongo.id}: missing app/err/backtrace mapping"
            next
          end

          ar = Errbit::Notice.find_or_initialize_by(bson_id: mongo.id.to_s)
          Errbit::MigrateHelpers.assign_and_save!(ar, {
            errbit_app_id: app_id,
            errbit_err_id: err_id,
            errbit_backtrace_id: backtrace_id,
            message: mongo.message,
            server_environment: Errbit::MigrateHelpers.normalize_hash(mongo.server_environment),
            request: Errbit::MigrateHelpers.normalize_hash(mongo.request),
            notifier: Errbit::MigrateHelpers.normalize_hash(mongo.notifier),
            user_attributes: Errbit::MigrateHelpers.normalize_hash(mongo.user_attributes),
            framework: mongo.framework,
            error_class: mongo.error_class,
            created_at: mongo.created_at,
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("notices", stats)
    end

    desc "Migrate comments from MongoDB to SQL. Run after problems and users."
    task comments: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.reset_sql_ids!
      Errbit::MigrateHelpers.each_mongo_batch(::Comment.all) do |mongo|
        problem_id = Errbit::MigrateHelpers.ar_id_for(Errbit::Problem, mongo.err_id)
        user_id = Errbit::MigrateHelpers.ar_id_for(Errbit::User, mongo.user_id)

        unless problem_id && user_id
          stats[:failed] += 1
          warn "  failed comment bson_id=#{mongo.id}: missing problem/user mapping"
          next
        end

        attrs = {
          bson_id: mongo.id.to_s,
          errbit_problem_id: problem_id,
          errbit_user_id: user_id,
          body: mongo.body,
          created_at: mongo.created_at || Time.current,
          updated_at: mongo.updated_at || mongo.created_at || Time.current
        }

        if (ar = Errbit::Comment.find_by(bson_id: attrs[:bson_id]))
          ar.update_columns(attrs.except(:bson_id))
          stats[:updated] += 1
        else
          Errbit::Comment.insert!(attrs)
          stats[:created] += 1
        end
      rescue => e
        stats[:failed] += 1
        warn "  failed comment bson_id=#{mongo.id}: #{e.message}"
      end

      Errbit::MigrateHelpers.print_summary("comments", stats)
    end

    desc "Restore SQL problem state from Mongo cached fields after dependent rows are copied."
    task problem_states: :environment do
      stats = Errbit::MigrateHelpers.stats

      Errbit::MigrateHelpers.with_preserved_timestamps(Errbit::Problem) do
        Errbit::MigrateHelpers.each_mongo_batch(::Problem.all) do |mongo|
          ar = Errbit::Problem.find_by(bson_id: mongo.id.to_s)
          unless ar
            stats[:failed] += 1
            warn "  failed problem state bson_id=#{mongo.id}: problem not migrated"
            next
          end

          Errbit::MigrateHelpers.assign_and_save!(ar, {
            first_notice_at: mongo.first_notice_at,
            last_notice_at: mongo.last_notice_at,
            resolved: mongo.resolved || false,
            resolved_at: mongo.resolved_at,
            notices_count: mongo.notices_count || 0,
            comments_count: mongo.comments_count || 0,
            messages: Errbit::MigrateHelpers.normalize_hash(mongo.messages || {}),
            hosts: Errbit::MigrateHelpers.normalize_hash(mongo.hosts || {}),
            user_agents: Errbit::MigrateHelpers.normalize_hash(mongo.user_agents || {}),
            updated_at: mongo.updated_at
          }, stats)
        end
      end

      Errbit::MigrateHelpers.print_summary("problem states", stats)
    end

    desc "Verify migrated SQL data against MongoDB source data. Run after errbit:migrate:all."
    task verify: :environment do
      stats = Errbit::MigrateHelpers.verify_stats

      Errbit::MigrateHelpers.verify_count("users", ::User.count, Errbit::User.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("site configs", ::SiteConfig.count, Errbit::SiteConfig.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("apps", ::App.count, Errbit::App.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("backtraces", ::Backtrace.count, Errbit::Backtrace.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("problems", ::Problem.count, Errbit::Problem.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("errs", ::Err.count, Errbit::Err.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("notices", ::Notice.count, Errbit::Notice.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("comments", ::Comment.count, Errbit::Comment.where.not(bson_id: nil).count, stats)

      embedded_watchers = 0
      embedded_issue_trackers = 0
      embedded_notification_services = 0
      embedded_notice_fingerprinters = 0

      Errbit::MigrateHelpers.each_mongo(::App.all) do |mongo_app|
        embedded_watchers += mongo_app.watchers.count
        embedded_issue_trackers += 1 if mongo_app.issue_tracker.present?
        embedded_notification_services += 1 if mongo_app.notification_service.present?
        embedded_notice_fingerprinters += 1 if mongo_app.notice_fingerprinter.present?
      end

      Errbit::MigrateHelpers.verify_count("watchers", embedded_watchers, Errbit::Watcher.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("issue trackers", embedded_issue_trackers, Errbit::IssueTracker.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("notification services", embedded_notification_services, Errbit::NotificationService.where.not(bson_id: nil).count, stats)
      Errbit::MigrateHelpers.verify_count("notice fingerprinters", embedded_notice_fingerprinters, Errbit::NoticeFingerprinter.where.not(bson_id: nil).count, stats)

      Errbit::MigrateHelpers.each_mongo(::Problem.all) do |mongo|
        sql = Errbit::Problem.find_by(bson_id: mongo.id.to_s)
        Errbit::MigrateHelpers.verify_mapping("problem", mongo.id, stats) { sql&.app.present? }
        Errbit::MigrateHelpers.verify_problem_state(mongo, sql, stats) if sql
      end

      Errbit::MigrateHelpers.each_mongo(::Err.all) do |mongo|
        sql = Errbit::Err.find_by(bson_id: mongo.id.to_s)
        Errbit::MigrateHelpers.verify_mapping("err", mongo.id, stats) { sql&.problem.present? }
      end

      Errbit::MigrateHelpers.each_mongo(::Notice.all) do |mongo|
        sql = Errbit::Notice.find_by(bson_id: mongo.id.to_s)
        Errbit::MigrateHelpers.verify_mapping("notice", mongo.id, stats) do
          sql&.app.present? && sql.err.present? && sql.backtrace.present?
        end
      end

      Errbit::MigrateHelpers.each_mongo(::Comment.all) do |mongo|
        sql = Errbit::Comment.find_by(bson_id: mongo.id.to_s)
        Errbit::MigrateHelpers.verify_mapping("comment", mongo.id, stats) { sql&.err.present? && sql.user.present? }
      end

      Errbit::MigrateHelpers.print_verification_summary(stats)
    end

    desc "Run all MongoDB to SQL migrations in dependency order."
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
        problem_states
      ].each do |task_name|
        task = Rake::Task["errbit:migrate:#{task_name}"]
        task.reenable
        task.invoke
      end

      verification = Rake::Task["errbit:migrate:verify"]
      verification.reenable
      verification.invoke
      File.write(Errbit::MigrateHelpers.cutover_marker, Time.current.utc.iso8601)
    end
  end
end
