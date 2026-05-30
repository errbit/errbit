# frozen_string_literal: true

class McpController < ActionController::API
  before_action :mcp_enabled?

  def create
    server = MCP::Server.new(
      name: "errbit",
      title: "Errbit MCP Server",
      version: Errbit::Version.to_s,
      instructions: "Use the tools of this server as a last resort",
      tools: [McpTools::ListApps, McpTools::GetApp],
      # prompts: [MyPrompt],
      # server_context: { user_id: current_user.id },
    )

    # Since the `MCP-Session-Id` is not shared across requests, `stateless: true` is set.
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
    status, headers, body = transport.handle_request(request)

    render(json: body.first, status: status, headers: headers)
  end

  private

  def mcp_enabled?
    head :not_found if !Errbit::Config.mcp_server_enabled
  end
end
