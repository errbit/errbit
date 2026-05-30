# frozen_string_literal: true

class McpController < ActionController::API
  def index
    render json: { version: MCP::VERSION }
  end
end
