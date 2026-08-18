# frozen_string_literal: true

module Errbit
  ##
  # Processes a new error report into the ActiveRecord-backed Errbit models.
  class ErrorReport
    attr_reader :api_key, :error_class, :framework, :message, :notice,
      :notifier, :problem, :problem_was_resolved, :request, :server_environment,
      :user_attributes

    def initialize(xml_or_attributes)
      @attributes = xml_or_attributes
      @attributes = Hoptoad.parse_xml!(@attributes) if @attributes.is_a? String
      @attributes = @attributes.with_indifferent_access
      @attributes.each { |key, value| instance_variable_set(:"@#{key}", value) }
    end

    def rails_env
      server_environment["environment-name"].presence || "development"
    end

    def app
      @app ||= Errbit::App.where(api_key: api_key).first
    end

    def backtrace
      @backtrace_record ||= Errbit::Backtrace.find_or_create(@backtrace)
    end

    def generate_notice!
      return unless valid?
      return @notice if @notice

      make_notice
      notice.err = error
      notice.save!

      retrieve_problem_was_resolved
      cache_attributes_on_problem
      email_notification
      services_notification
      @notice
    end

    def make_notice
      @notice = Errbit::Notice.new(
        app: app,
        message: message,
        error_class: error_class,
        backtrace: backtrace,
        request: request,
        server_environment: server_environment,
        notifier: notifier,
        user_attributes: user_attributes,
        framework: framework
      )
    end

    def retrieve_problem_was_resolved
      @problem_was_resolved = Errbit::Problem.exists?(id: @error.errbit_problem_id, resolved: true)
    end

    def cache_attributes_on_problem
      @problem = Errbit::Problem.cache_notice(@error.errbit_problem_id, @notice)
    end

    def should_email?
      problem_was_resolved ||
        app.email_at_notices.include?(0) ||
        app.email_at_notices.include?(@problem.notices_count)
    end

    def email_notification
      return unless app.emailable? && should_email?

      Errbit::Mailer.with(error_report: self).err_notification.deliver_now
    rescue => e
      HoptoadNotifier.notify(e)
    end

    def should_notify?
      problem_was_resolved ||
        app.notification_service.notify_at_notices.include?(0) ||
        app.notification_service.notify_at_notices.include?(@problem.notices_count)
    end

    def services_notification
      return unless app.notification_service_configured? && should_notify?

      app.notification_service.create_notification(problem)
    rescue => e
      HoptoadNotifier.notify(e)
    end

    def error
      @error ||= app.find_or_create_err!(
        error_class: error_class,
        environment: rails_env,
        fingerprint: fingerprint
      )
    end

    def valid?
      app.present?
    end

    def should_keep?
      app_version = server_environment["app-version"] || ""
      current_version = app.current_app_version
      return true if current_version.blank?
      return false if app_version.length <= 0

      Gem::Version.new(app_version) >= Gem::Version.new(current_version)
    end

    def fingerprint
      app.notice_fingerprinter.generate(api_key, notice, backtrace)
    end
  end
end
