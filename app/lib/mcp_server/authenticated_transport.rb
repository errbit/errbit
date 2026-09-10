# frozen_string_literal: true

require "digest"

module McpServer
  class AuthenticatedTransport
    def initialize(app)
      @app = app
    end

    def call(env)
      return not_found(env) unless Errbit::Config.mcp_server_enabled
      return unauthorized(env) unless authenticated?(env["HTTP_AUTHORIZATION"])

      @app.call(env)
    rescue StandardError => e
      Rails.logger.error("MCP request failed request_id=#{request_id(env)} error=#{e.class.name}")
      internal_error(env)
    end

    private

    def authenticated?(authorization)
      expected_token = Errbit::Config.mcp_auth_token
      return false if expected_token.blank? || authorization.blank?

      scheme, token = authorization.split(" ", 2)
      scheme&.casecmp?("Bearer") && token.present? && secure_compare(token, expected_token)
    end

    def secure_compare(token, expected)
      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(token),
        Digest::SHA256.hexdigest(expected)
      )
    end

    def not_found(env)
      response(404, {error: "Not found"}, env)
    end

    def unauthorized(env)
      response(401, {error: "Unauthorized"}, env, "www-authenticate" => "Bearer")
    end

    def internal_error(env)
      response(500, {error: "mcp_internal_error", request_id: request_id(env)}, env)
    end

    def response(status, body, env, headers = {})
      headers = {"content-type" => "application/json", "cache-control" => "no-store"}.merge(headers)
      headers["x-request-id"] = request_id(env) if request_id(env).present?
      [status, headers, [body.to_json]]
    end

    def request_id(env)
      env["action_dispatch.request_id"] || "unknown"
    end
  end
end
