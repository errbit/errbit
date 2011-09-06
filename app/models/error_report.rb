require 'digest/md5'


class ErrorReport
  
  
  
  def initialize(xml_or_attributes)
    @attributes = (xml_or_attributes.is_a?(String) ? Hoptoad.parse_xml!(xml_or_attributes) : xml_or_attributes).with_indifferent_access
  end
  
  
  
  def klass
    @attributes[:klass]
  end
  
  def message
    @attributes[:message]
  end
  
  def backtrace
    @attributes[:backtrace]
  end
  
  def request
    @attributes[:request]
  end
  
  def server_environment
    @attributes[:server_environment]
  end
  
  def api_key
    @attributes[:api_key]
  end
  
  def notifier
    @attributes[:notifier]
  end
  
  
  
  def fingerprint
    @fingerprint ||= ErrorReport.get_fingerprint(self)
  end
  
  def self.get_fingerprint(report)
    Digest::MD5.hexdigest(report.backtrace[0].to_s)
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
