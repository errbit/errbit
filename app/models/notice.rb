require 'recurse'

class Notice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :message
  field :server_environment, :type => Hash
  field :request, :type => Hash
  field :notifier, :type => Hash
  field :user_attributes, :type => Hash
  field :framework
  field :error_class
  delegate :lines, :to => :backtrace, :prefix => true
  delegate :problem, :to => :err

  belongs_to :app
  belongs_to :err
  belongs_to :backtrace, :index => true

  index(:created_at => 1)
  index(:err_id => 1, :created_at => 1, :_id => 1)

  before_save :sanitize
  before_destroy :problem_recache

  validates_presence_of :backtrace_id, :server_environment, :notifier

  scope :ordered, ->{ order_by(:created_at.asc) }
  scope :reverse_ordered, ->{ order_by(:created_at.desc) }
  scope :for_errs, Proc.new { |errs|
    where(:err_id.in => errs.all.map(&:id))
  }

  def user_agent
    agent_string = env_vars['HTTP_USER_AGENT']
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
  end

  def user_agent_string
    if user_agent.nil? || user_agent.none?
      "N/A"
    else
      "#{user_agent.browser} #{user_agent.version} (#{user_agent.os})"
    end
  end

  def environment_name
    n = server_environment['server-environment'] || server_environment['environment-name']
    n.blank? ? 'development' : n
  end

  def component
    request['component']
  end

  def action
    request['action']
  end

  def where
    where = component.to_s.dup
    where << "##{action}" if action.present?
    where
  end

  def request
    super || {}
  end

  def url
    request['url']
  end

  def host
    uri = url && URI.parse(url)
    uri && uri.host || "N/A"
  rescue URI::InvalidURIError
    "N/A"
  end

  def to_curl
    return "N/A" if url.blank?
    headers = %w(Accept Accept-Encoding Accept-Language Cookie Referer User-Agent).each_with_object([]) do |name, h|
      if value = env_vars["HTTP_#{name.underscore.upcase}"]
        h << "-H '#{name}: #{value}'"
      end
    end

    "curl -X #{env_vars['REQUEST_METHOD'] || 'GET'} #{headers.join(' ')} #{url}"
  end

  def env_vars
    vars = request['cgi-data']
    vars.is_a?(Hash) ? vars : {}
  end

  def params
    request['params'] || {}
  end

  def session
    request['session'] || {}
  end

  ##
  # TODO: Move on decorator maybe
  #
  def project_root
    if server_environment
      server_environment['project-root'] || ''
    end
  end

  def app_version
    if server_environment
      server_environment['app-version'] || ''
    end
  end

  # filter memory addresses out of object strings
  # example: "#<Object:0x007fa2b33d9458>" becomes "#<Object>"
  def filtered_message
    message.gsub(/(#<.+?):[0-9a-f]x[0-9a-f]+(>)/, '\1\2')
  end

  protected

  def problem_recache
    problem.uncache_notice(self)
  end

  def sanitize
    [:server_environment, :request, :notifier].each do |h|
      send("#{h}=",sanitize_hash(send(h)))
    end
  end

  def sanitize_hash(h)
    h.recurse do |h|
      h.inject({}) do |h,(k,v)|
        if k.is_a?(String)
          h[k.gsub(/\./,'&#46;').gsub(/^\$/,'&#36;')] = v
        else
          h[k] = v
        end
        h
      end
    end
  end
end
