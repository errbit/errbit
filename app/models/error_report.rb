require 'digest/sha1'
require 'hoptoad_notifier'

class ErrorReport
  attr_reader :error_class, :message, :request, :server_environment, :api_key, :notifier, :user_attributes, :current_user, :framework

  def initialize(xml_or_attributes)
    @attributes = (xml_or_attributes.is_a?(String) ? Hoptoad.parse_xml!(xml_or_attributes) : xml_or_attributes).with_indifferent_access
    @attributes.each{|k, v| instance_variable_set(:"@#{k}", v) }
  end

  def fingerprint
    @fingerprint ||= Digest::SHA1.hexdigest(fingerprint_source.to_s)
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
    @app ||= App.find_by_api_key!(api_key)
  end

  def backtrace
    @normalized_backtrace ||= Backtrace.find_or_create(:raw => @backtrace)
  end

  def generate_notice!
    notice = Notice.new(
      :message => message,
      :error_class => error_class,
      :backtrace_id => backtrace.id,
      :request => request,
      :server_environment => server_environment,
      :notifier => notifier,
      :user_attributes => user_attributes,
      :current_user => current_user,
      :framework => framework
    )

    err = app.find_or_create_err!(
      :error_class => error_class,
      :component => component,
      :action => action,
      :environment => rails_env,
      :fingerprint => fingerprint)

    err.notices << notice
    notice
  end

  private
  def fingerprint_source
    {
      :backtrace => backtrace.id,
      :error_class => error_class,
      :component => component,
      :action => action,
      :environment => rails_env,
      :api_key => api_key
    }
  end

end

