class Notice
  include ActiveModel::Serializers::Xml

  UNAVAILABLE = "N/A"

  # Mongo will not accept index keys larger than 1,024 bytes and that includes
  # some amount of BSON encoding overhead, so keep it under 1,000 bytes to be
  # safe.
  MESSAGE_LENGTH_LIMIT = 1_000

  include Mongoid::Document
  include Mongoid::Timestamps

  field :message
  field :server_environment, type: Hash
  field :request, type: Hash
  field :notifier, type: Hash
  field :user_attributes, type: Hash
  field :framework
  field :error_class
  delegate :lines, to: :backtrace, prefix: true
  delegate :problem, to: :err

  belongs_to :app
  belongs_to :err
  belongs_to :backtrace, index: true

  index(created_at: 1)
  index(err_id: 1, created_at: 1, _id: 1)

  before_save :sanitize
  before_destroy :problem_recache

  validates :backtrace_id, :server_environment, :notifier, presence: true

  scope :ordered, -> { order_by(:created_at.asc) }
  scope :reverse_ordered, -> { order_by(:created_at.desc) }
  scope :for_errs, lambda { |errs|
    where(:err_id.in => errs.all.map(&:id))
  }

  # Overwrite the default setter to make sure the message length is no larger
  # than the limit we impose.
  def message=(m)
    truncated_m = m.mb_chars.compose.limit(MESSAGE_LENGTH_LIMIT).to_s
    super(m.is_a?(String) ? truncated_m : m)
  end

  def user_agent
    agent_string = env_vars["HTTP_USER_AGENT"]
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
  end

  def user_agent_string
    if user_agent.nil? || user_agent.none?
      UNAVAILABLE
    else
      "#{user_agent.browser} #{user_agent.version} (#{user_agent.os})"
    end
  end

  def environment_name
    n = server_environment["server-environment"] || server_environment["environment-name"]
    n.blank? ? "development" : n
  end

  def component
    request["component"]
  end

  def action
    request["action"]
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
    request["url"]
  end

  def host
    uri = url && URI.parse(url)
    return uri.host if uri && uri.host.present?
    UNAVAILABLE
  rescue URI::InvalidURIError
    UNAVAILABLE
  end

  def env_vars
    vars = request["cgi-data"]
    vars.is_a?(Hash) ? vars : {}
  end

  def params
    request["params"] || {}
  end

  def session
    request["session"] || {}
  end

  ##
  # TODO: Move on decorator maybe
  #
  def project_root
    server_environment["project-root"] || "" if server_environment
  end

  def app_version
    server_environment["app-version"] || "" if server_environment
  end

  # filter memory addresses out of object strings
  # example: "#<Object:0x007fa2b33d9458>" becomes "#<Object>"
  def filtered_message
    message.gsub(/(#<.+?):[0-9a-f]x[0-9a-f]+(>)/, '\1\2')
  end

private

  def problem_recache
    problem.uncache_notice(self)
  end

  def sanitize
    [:server_environment, :request, :notifier].each do |h|
      send("#{h}=", sanitize_hash(send(h)))
    end
  end

  def sanitize_hash(hash)
    hash.recurse do |recurse_hash|
      recurse_hash.inject({}) do |h, (k, v)|
        if k.is_a?(String)
          h[k.gsub(/\./, "&#46;").gsub(/^\$/, "&#36;")] = v
        else
          h[k] = v
        end
        h
      end
    end
  end
end
