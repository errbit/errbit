# frozen_string_literal: true

module McpServer
  class Endpoint
    def call(env)
      AuthenticatedTransport.new(transport).call(env)
    end

    private

    def transport
      MCP::Server::Transports::StreamableHTTPTransport.new(
        server,
        stateless: true,
        serve_subscriptions_listen: false,
        enable_json_response: true,
        max_request_bytes: 1_000_000,
        allowed_hosts: Errbit::Config.mcp_allowed_hosts
      )
    end

    def server
      MCP::Server.new(
        name: "errbit",
        title: "Errbit MCP Server",
        version: Errbit::Version.to_s,
        instructions: "Use these tools to investigate Errbit applications.",
        tools: [Tools::ListApps, Tools::GetApp, Tools::ListProblems, Tools::GetProblem, Tools::GetLatestNotice, Tools::GetNotice, Tools::ListNotices, Tools::GetIncidentSummary, Tools::GetAirbrakeSetupGuidance]
      )
    end
  end
end
