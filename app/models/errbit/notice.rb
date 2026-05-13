# frozen_string_literal: true

module Errbit
  class Notice < ApplicationRecord
    UNAVAILABLE = "N/A"

    # Mongo will not accept index keys larger than 1,024 bytes and that includes
    # some amount of BSON encoding overhead, so keep it under 1,000 bytes to be
    # safe.
    MESSAGE_LENGTH_LIMIT = 1_000

    belongs_to :app,
      class_name: "Errbit::App",
      foreign_key: :errbit_app_id,
      inverse_of: :notices

    belongs_to :err,
      class_name: "Errbit::Err",
      foreign_key: :errbit_err_id,
      inverse_of: :notices

    belongs_to :backtrace,
      class_name: "Errbit::Backtrace",
      foreign_key: :errbit_backtrace_id

    delegate :lines, to: :backtrace, prefix: true
    delegate :problem, to: :err

    validates :server_environment, presence: true
    validates :notifier, presence: true

    before_save :sanitize

    scope :ordered, -> { order(created_at: :asc) }
    scope :reverse_ordered, -> { order(created_at: :desc) }
    scope :for_errs, ->(errs) { where(errbit_err_id: errs.map(&:id)) }

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

    def sanitize
      [:server_environment, :request, :notifier].each do |h|
        send(:"#{h}=", sanitize_hash(send(h)))
      end
    end

    def sanitize_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(k, v), result|
        new_key = k.is_a?(String) ? k.gsub(/\./, "&#46;").gsub(/^\$/, "&#36;") : k
        result[new_key] = v.is_a?(Hash) ? sanitize_hash(v) : v
      end
    end
  end
end
