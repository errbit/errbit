require 'hoptoad_notifier'

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
  attr_reader :error_class, :message, :request, :server_environment, :api_key, :notifier, :user_attributes, :framework

  def initialize(xml_or_attributes)
    @attributes = (xml_or_attributes.is_a?(String) ? Hoptoad.parse_xml!(xml_or_attributes) : xml_or_attributes).with_indifferent_access
    @attributes.each{|k, v| instance_variable_set(:"@#{k}", v) }
  end

  def rails_env
    server_environment['environment-name'] || 'development'
  end

  def component
    request['component'] || 'unknown'
  end

  def action
    request['action']
  end

  def app
    @app ||= App.where(:api_key => api_key).first
  end

  def backtrace
    @normalized_backtrace ||= Backtrace.find_or_create(:raw => @backtrace)
  end

  def generate_notice!
    return unless valid?
    return @notice if @notice
    @notice = Notice.new(
      :message => message,
      :error_class => error_class,
      :backtrace_id => backtrace.id,
      :request => request,
      :server_environment => server_environment,
      :notifier => notifier,
      :user_attributes => user_attributes,
      :framework => framework
    )
    error.notices << @notice
    @notice
  end
  attr_reader :notice

  ##
  # Error associate to this error_report
  #
  # Can already exist or not
  #
  # @return [ Error ]
  def error
    @error ||= app.find_or_create_err!(
      :error_class => error_class,
      :component => component,
      :action => action,
      :environment => rails_env,
      :fingerprint => fingerprint
    )
  end

  def valid?
    !!app
  end

  private

  def fingerprint
    @fingerprint ||= Fingerprint.generate(notice, api_key)
  end

end
