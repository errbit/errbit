# frozen_string_literal: true

require "airbrake"
require "airbrake/rack/middleware"

module Errbit
  module SelfErrorReporter
    SELF_APP_NAME = "Self.Errbit"
    # Preserve the previous notifier's public-environment behavior.
    NON_PUBLIC_ENVIRONMENTS = ["development", "test"].freeze

    class Middleware < Airbrake::Rack::Middleware
      private

      def notify_airbrake(exception)
        SelfErrorReporter.notify(
          exception,
          request: Airbrake::Rack::RequestStore[:request]
        )
      end
    end

    REQUEST_FILTERS = [
      Airbrake::Rack::RouteFilter.new,
      Airbrake::Rack::ContextFilter.new,
      Airbrake::Rack::HttpHeadersFilter.new,
      Airbrake::Rack::SessionFilter.new
    ].freeze

    module_function

    def notify(exception, request: nil)
      return unless public_environment?
      return if ignored_exception?(exception)

      app = self_app
      return unless app

      notice = build_notice(exception, request)
      return unless notice

      payload = notice_payload(notice, app)

      AirbrakeApi::V3::NoticeParser.new(payload).report.generate_notice!
    rescue => e
      Rails.logger.error("Errbit::SelfErrorReporter failed: #{e.class} - #{e.message}")
    end

    def ignored_exception?(exception)
      exception.is_a?(Mongoid::Errors::DocumentNotFound)
    end

    def public_environment?
      NON_PUBLIC_ENVIRONMENTS.exclude?(Rails.env.to_s)
    end

    def self_app
      App.where(name: SELF_APP_NAME).first_or_create do |app|
        app.github_repo = "errbit/errbit"
      end
    end

    def notice_payload(notice, app)
      sanitize_notice(notice)
      payload = JSON.parse(notice.to_json)
      payload["environment"] = notice[:environment].merge(request_environment(notice))
      payload.merge("key" => app.api_key)
    end

    def sanitize_notice(notice)
      [:errors, :context, :environment, :session, :params].each do |section|
        value = notice[section]
        value.replace(scrub_values(value)) if value.respond_to?(:replace)
      end
    end

    def request_environment(notice)
      request = notice.stash[:rack_request]
      return {} unless request

      request.env.each_with_object({}) do |(key, value), environment|
        environment[key] = value.nil? ? nil : scrub_values(value.to_s)
      end
    end

    def build_notice(exception, request)
      notice = Airbrake.build_notice(exception)
      return unless notice

      notice.stash[:rack_request] = request if request
      refine_notice(notice)
      notice
    end

    def refine_notice(notice)
      REQUEST_FILTERS.each do |filter|
        filter.call(notice)
      end

      request = notice.stash[:rack_request]
      notice[:params].merge!(safe_request_params(request)) if request
    end

    def safe_request_params(request)
      form_params = request.request_parameters
      query_params = Rack::Utils.parse_query(request.env["QUERY_STRING"].to_s)
      scrub_values(form_params.merge(query_params))
    rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError
      scrub_values(query_params || {})
    end

    def scrub_values(value)
      case value
      when Hash
        scrub_hash(value)
      when Array
        value.map { |item| scrub_values(item) }
      when String
        value.dup.force_encoding(Encoding::UTF_8).scrub
      else
        value
      end
    end

    def scrub_hash(value)
      value.to_h.each_with_object({}) do |(key, item), scrubbed|
        scrubbed[scrub_values(key)] = scrub_values(item)
      end
    end
  end
end
