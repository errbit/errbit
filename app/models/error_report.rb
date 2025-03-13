require "hoptoad_notifier"

##
# Processes a new error report.
#
# Accepts a hash with the following attributes:
#
# * <tt>:error_class</tt> - the class of error
# * <tt>:message</tt> - the error message
# * <tt>:backtrace</tt> - an array of stack trace lines
#
# * <tt>:request</tt> - a hash of values describing the request
# * <tt>:server_environment</tt> - a hash of values describing the server environment
#
# * <tt>:notifier</tt> - information to identify the source of the error report
#
class ErrorReport
  attr_reader :api_key
  attr_reader :error_class
  attr_reader :framework
  attr_reader :message
  attr_reader :notice
  attr_reader :notifier
  attr_reader :problem
  attr_reader :problem_was_resolved
  attr_reader :request
  attr_reader :server_environment
  attr_reader :user_attributes

  def initialize(xml_or_attributes)
    @attributes = xml_or_attributes
    @attributes = Hoptoad.parse_xml!(@attributes) if @attributes.is_a? String
    @attributes = @attributes.with_indifferent_access
    @attributes.each { |k, v| instance_variable_set(:"@#{k}", v) }
  end

  def rails_env
    rails_env = server_environment["environment-name"]
    rails_env = "development" if rails_env.blank?
    rails_env
  end

  def app
    @app ||= App.where(api_key: api_key).first
  end

  def backtrace
    @normalized_backtrace ||= Backtrace.find_or_create(@backtrace)
  end

  def generate_notice!
    return unless valid?
    return @notice if @notice

    make_notice
    notice.err_id = error.id
    notice.save!

    retrieve_problem_was_resolved
    cache_attributes_on_problem
    email_notification
    services_notification
    @notice
  end

  def make_notice
    @notice = Notice.new(
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
    @problem_was_resolved = Problem.where("_id" => @error.problem_id, :resolved => true).exists?
  end

  # Update problem cache with information about this notice
  def cache_attributes_on_problem
    @problem = Problem.cache_notice(@error.problem_id, @notice)
  end

  def should_email?
    problem_was_resolved ||
      app.email_at_notices.include?(0) ||
      app.email_at_notices.include?(@problem.notices_count)
  end

  # Send email notification if needed
  def email_notification
    return unless app.emailable? && should_email?
    Mailer.err_notification(self).deliver_now
  rescue => e
    HoptoadNotifier.notify(e)
  end

  def should_notify?
    problem_was_resolved ||
      app.notification_service.notify_at_notices.include?(0) ||
      app.notification_service.notify_at_notices.include?(@problem.notices_count)
  end

  # Launch all notification define on the app associate to this notice
  def services_notification
    return unless app.notification_service_configured? && should_notify?
    app.notification_service.create_notification(problem)
  rescue => e
    HoptoadNotifier.notify(e)
  end

  ##
  # Error associate to this error_report
  #
  # Can already exist or not
  #
  # @return [ Error ]
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
    return true unless current_version.present?
    return false if app_version.length <= 0
    Gem::Version.new(app_version) >= Gem::Version.new(current_version)
  end

  def fingerprint
    app.notice_fingerprinter.generate(api_key, notice, backtrace)
  end
end
