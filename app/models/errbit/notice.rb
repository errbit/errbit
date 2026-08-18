# frozen_string_literal: true

module Errbit
  class Notice < ApplicationRecord
    UNAVAILABLE = "N/A"
    MESSAGE_LENGTH_LIMIT = 1_000

    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "Notice")
    end

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
    before_destroy :problem_recache

    scope :ordered, -> { order(created_at: :asc) }
    scope :reverse_ordered, -> { order(created_at: :desc) }
    scope :for_errs, ->(errs) { where(errbit_err_id: errs.map(&:id)) }

    def message=(message)
      super(message.is_a?(String) ? message.truncate_bytes(MESSAGE_LENGTH_LIMIT, omission: nil) : message)
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
      name = server_environment["server-environment"] || server_environment["environment-name"]
      name.blank? ? "development" : name
    end

    def component
      request["component"]
    end

    def action
      request["action"]
    end

    def where
      location = component.to_s.dup
      location << "##{action}" if action.present?
      location
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

    def filtered_message
      message.gsub(/(#<.+?):[0-9a-f]x[0-9a-f]+(>)/, '\1\2')
    end

    private

    def problem_recache
      problem&.uncache_notice(self)
    end

    def sanitize
      [:server_environment, :request, :notifier].each do |hash|
        send(:"#{hash}=", sanitize_hash(send(hash)))
      end
    end

    def sanitize_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        new_key = key.is_a?(String) ? key.gsub(".", "&#46;").gsub(/^\$/, "&#36;") : key
        result[new_key] = value.is_a?(Hash) ? sanitize_hash(value) : value
      end
    end
  end
end
