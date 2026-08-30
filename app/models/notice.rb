# frozen_string_literal: true

class Notice
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::Serializers::Xml

  UNAVAILABLE = "N/A"
  FILTERED_TEXT = "[FILTERED]"

  # Fail closed for sensitive-looking keys, even when this drops benign diagnostics.
  SENSITIVE_KEY_PATTERN = /passw|secret|token|api[_-]?key|authorization|credential|cookie|csrf|session|salt|certificate|crypt|otp|ssn|cvv|cvc/i
  INTERNAL_CGI_KEY = /\A(?:action_dispatch|action_controller|rack(?:[._]|\z)|puma(?:[._]|\z)|warden|rails_rack|routes?_|ROUTES_)/i

  # Mongo will not accept index keys larger than 1,024 bytes and that includes
  # some amount of BSON encoding overhead, so keep it under 1,000 bytes to be
  # safe.
  MESSAGE_LENGTH_LIMIT = 1_000

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

  validates :backtrace_id, presence: true
  validates :server_environment, presence: true
  validates :notifier, presence: true

  scope :ordered, -> { order_by(:created_at.asc) }
  scope :reverse_ordered, -> { order_by(:created_at.desc) }
  scope :for_errs, lambda { |errs|
    where(:err_id.in => errs.all.map(&:id))
  }

  # Overwrite the default setter to make sure the message length is no larger
  # than the limit we impose.
  def message=(m)
    truncated_m = m.truncate_bytes(MESSAGE_LENGTH_LIMIT, omission: nil)

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
    privacy = privacy_sanitization?
    self.server_environment = sanitize_hash(server_environment, privacy: privacy)
    self.request = sanitize_request(request, privacy: privacy)
    self.notifier = sanitize_hash(notifier, privacy: privacy)
    self.user_attributes = sanitize_hash(user_attributes, privacy: privacy)
  end

  def sanitize_request(value, privacy:)
    return value unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, child), sanitized|
      key_name = key.to_s
      session_container = key_name.casecmp?("session") && child.is_a?(Hash)

      sanitized_key = sanitize_key(key)
      sanitized[sanitized_key] = if privacy && !session_container && sensitive_key?(key)
        FILTERED_TEXT
      elsif session_container
        sanitize_value(child, privacy: privacy)
      elsif key_name == "cgi-data"
        sanitize_cgi_data(child, privacy: privacy)
      elsif key_name == "url" && privacy
        sanitize_url(child)
      else
        sanitize_value(child, privacy: privacy)
      end
    end
  end

  def sanitize_cgi_data(value, privacy:)
    return value unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, child), sanitized|
      next if privacy && INTERNAL_CGI_KEY.match?(key.to_s)

      sanitized_value = if privacy && sensitive_key?(key)
        FILTERED_TEXT
      elsif privacy && key.to_s == "QUERY_STRING"
        sanitize_query_string(child)
      elsif privacy && ["REQUEST_URI", "ORIGINAL_FULLPATH"].include?(key.to_s)
        sanitize_url(child)
      else
        sanitize_value(child, privacy: privacy)
      end
      sanitized[sanitize_key(key)] = sanitized_value
    end
  end

  def sanitize_hash(value, privacy:)
    sanitize_value(value, privacy: privacy)
  end

  def sanitize_value(value, privacy:)
    case value
    when Hash
      value.each_with_object({}) do |(key, child), sanitized|
        sanitized_key = sanitize_key(key)
        sanitized[sanitized_key] = if privacy && sensitive_key?(key)
          FILTERED_TEXT
        else
          sanitize_value(child, privacy: privacy)
        end
      end
    when Array
      value.map { |child| sanitize_value(child, privacy: privacy) }
    when String
      sanitize_storage_string(value)
    else
      value
    end
  end

  def sensitive_key?(key)
    SENSITIVE_KEY_PATTERN.match?(key.to_s) || custom_sensitive_keys.include?(key.to_s.downcase)
  end

  def privacy_sanitization?
    Errbit::Config.sanitize_notice_data != false
  end

  def custom_sensitive_keys
    @custom_sensitive_keys ||= Errbit::Config.sensitive_keys.to_s.split(",").map { |key| key.strip.downcase }.reject(&:blank?)
  end

  def sanitize_key(key)
    key.is_a?(String) ? key.gsub(".", "&#46;").gsub(/^\$/, "&#36;") : key
  end

  def sanitize_url(value)
    return value unless value.is_a?(String)

    value = value.dup.force_encoding(Encoding::UTF_8)
    return nil unless value.valid_encoding?

    value = value.split("#", 2).first
    value = value.sub(%r{\A([a-z][a-z0-9+.-]*://|//)[^/?#]*@}i, '\1')
    path, query = value.split("?", 2)
    return value unless query

    sanitized_query = sanitize_query_string(query)
    sanitized_query.present? ? "#{path}?#{sanitized_query}" : path
  end

  def sanitize_storage_string(value)
    value = value.dup.force_encoding(Encoding::UTF_8)
    value.valid_encoding? ? value : nil
  end

  def sanitize_query_string(value)
    return value unless value.is_a?(String)
    value = value.dup.force_encoding(Encoding::UTF_8).split("#", 2).first
    return nil unless valid_percent_encoding?(value)

    pairs = URI.decode_www_form(value)
    pairs.map! { |key, val| sensitive_key?(key) ? [key, FILTERED_TEXT] : [key, val] }
    URI.encode_www_form(pairs)
  rescue ArgumentError, Encoding::InvalidByteSequenceError
    nil
  end

  def valid_percent_encoding?(value)
    value.valid_encoding? &&
      !value.match?(/%(?![0-9A-Fa-f]{2})/) &&
      value.scan(/(?:%[0-9A-Fa-f]{2})+/).all? do |encoded_bytes|
        [encoded_bytes.delete("%")].pack("H*").force_encoding(Encoding::UTF_8).valid_encoding?
      end
  end
end
