# frozen_string_literal: true

raise "ERRBIT_MCP_AUTH_TOKEN must be set when ERRBIT_MCP_SERVER is enabled in production" if Errbit::Config.mcp_server_enabled && Errbit::Config.mcp_auth_token.blank? && Rails.env.production?
