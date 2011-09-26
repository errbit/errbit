require 'digest/md5'
require 'hoptoad_notifier'

class ErrorReport
  attr_reader :klass, :message, :backtrace, :request, :server_environment, :api_key, :notifier

  def initialize(xml_or_attributes)
    @attributes = (xml_or_attributes.is_a?(String) ? Hoptoad.parse_xml!(xml_or_attributes) : xml_or_attributes).with_indifferent_access
    @attributes.each{|k, v| instance_variable_set(:"@#{k}", v) }
  end

  def fingerprint
    @fingerprint ||= Digest::MD5.hexdigest(backtrace[0].to_s)
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

  def generate_notice!
    notice = Notice.new(
      :message => message,
      :backtrace => backtrace,
      :request => request,
      :server_environment => server_environment,
      :notifier => notifier)

    err = app.find_or_create_err!(
      :klass => klass,
      :component => component,
      :action => action,
      :environment => rails_env,
      :fingerprint => fingerprint)

    err.notices << notice
    notice
  end
end

