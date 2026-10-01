# frozen_string_literal: true

require "rails_helper"

RSpec.describe McpServer::AuthenticatedTransport do
  let(:token) { "mcp-test-token" }
  let(:env) do
    {
      "HTTP_AUTHORIZATION" => "Bearer #{token}",
      "action_dispatch.request_id" => "request-123"
    }
  end
  let(:internal_error_response) do
    [
      500,
      {
        "content-type" => "application/json",
        "cache-control" => "no-store",
        "x-request-id" => "request-123"
      },
      ['{"error":"mcp_internal_error","request_id":"request-123"}']
    ]
  end

  before do
    allow(Errbit::Config).to receive(:mcp_server_enabled).and_return(true)
    allow(Errbit::Config).to receive(:mcp_auth_token).and_return(token)
  end

  it "returns a stable internal error without exposing exception details" do
    app = ->(_) { raise "secret notice payload" }

    expect(described_class.new(app).call(env)).to eq(internal_error_response)
  end

  it "logs only the request ID and exception class" do
    app = ->(_) { raise "secret notice payload" }
    expect(Rails.logger).to receive(:error).with("MCP request failed request_id=request-123 error=RuntimeError")

    described_class.new(app).call(env)
  end
end
