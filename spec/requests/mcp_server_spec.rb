# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP server", type: :request do
  let(:token) { "mcp-test-token" }
  let(:headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json",
      "HOST" => Errbit::Config.host
    }
  end

  before do
    allow(Errbit::Config).to receive(:mcp_server_enabled).and_return(true)
    allow(Errbit::Config).to receive(:mcp_auth_token).and_return(token)
  end

  it "returns not found when disabled" do
    allow(Errbit::Config).to receive(:mcp_server_enabled).and_return(false)

    mcp_request("tools/list", authorization: nil)

    expect(response).to have_http_status(:not_found)
  end

  it "rejects missing, malformed, and invalid credentials without exposing the token" do
    [nil, "Basic #{token}", "Bearer incorrect-token"].each do |authorization|
      mcp_request("tools/list", authorization: authorization)

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to eq("Bearer")
      expect(response.body).not_to include(token)
    end
  end

  it "accepts bearer authentication schemes case-insensitively" do
    ["bearer", "BEARER"].each do |scheme|
      mcp_request("tools/list", authorization: "#{scheme} #{token}")

      expect(response).to have_http_status(:ok)
    end
  end

  it "rejects request bodies larger than 1 MB" do
    mcp_request(
      "tools/list",
      authorization: "Bearer #{token}",
      payload: {jsonrpc: "2.0", id: 1, method: "tools/list", padding: "x" * 1_000_001}.to_json
    )

    expect(response).to have_http_status(:content_too_large)
  end

  it "lists the advertised read-only tools for a valid credential" do
    mcp_request("tools/list", authorization: "Bearer #{token}")

    expect(response).to have_http_status(:ok)
    expect(json.dig("result", "tools").pluck("name")).to contain_exactly("errbit_list_apps", "errbit_get_app", "errbit_list_problems", "errbit_get_problem", "errbit_get_latest_notice", "errbit_get_notice", "errbit_list_notices", "errbit_get_incident_summary", "errbit_get_airbrake_setup_guidance")
    expect(response.headers).not_to have_key("Access-Control-Allow-Origin")
  end

  it "rejects a request with an unapproved host" do
    mcp_request("tools/list", authorization: "Bearer #{token}", headers: {"HOST" => "unapproved.example.com"})

    expect(response).to have_http_status(:forbidden)
  end

  it "rejects non-POST MCP requests" do
    get "/mcp", headers: headers.merge("Authorization" => "Bearer #{token}")

    expect(response).to have_http_status(:method_not_allowed)
  end

  it "rejects requests without the JSON media type" do
    mcp_request(
      "tools/list",
      authorization: "Bearer #{token}",
      headers: {"CONTENT_TYPE" => "text/plain"}
    )

    expect(response).to have_http_status(:unsupported_media_type)
  end

  it "accepts the documented MCP protocol version" do
    mcp_request(
      "tools/list",
      authorization: "Bearer #{token}",
      headers: {"HTTP_MCP_PROTOCOL_VERSION" => "2025-03-26"}
    )

    expect(response).to have_http_status(:ok)
  end

  it "lists bounded app metadata without API keys" do
    app = create(:app, api_key: "sensitive-api-key")

    mcp_request("tools/call", {name: "errbit_list_apps", arguments: {per_page: 1}}, authorization: "Bearer #{token}")

    result = json.dig("result", "structuredContent")
    expect(result.fetch("apps")).to include(hash_including("id" => app.id.to_s, "name" => app.name))
    expect(result.fetch("per_page")).to eq(1)
    expect(response.body).not_to include("sensitive-api-key")
  end

  it "orders apps with the same name by ID" do
    first_app = build(:app, name: "Same name")
    second_app = build(:app, name: "Same name")
    first_app.save!(validate: false)
    second_app.save!(validate: false)
    expected_ids = [first_app.id, second_app.id].sort

    mcp_request("tools/call", {name: "errbit_list_apps", arguments: {per_page: 100}}, authorization: "Bearer #{token}")

    actual_ids = json.dig("result", "structuredContent", "apps").filter_map do |app|
      app.fetch("id") if expected_ids.include?(app.fetch("id"))
    end
    expect(actual_ids).to eq(expected_ids)
  end

  it "searches apps by name without exposing other app metadata" do
    matching = create(:app, name: "Checkout production", api_key: "sensitive-api-key")
    create(:app, name: "Billing production")

    mcp_request(
      "tools/call",
      {name: "errbit_list_apps", arguments: {search: "CHECKOUT"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent", "apps").map { |app| app.fetch("id") }).to eq([matching.id.to_s])
    expect(response.body).not_to include("sensitive-api-key")
  end

  it "returns safe app details and a stable error for an unknown app" do
    app = create(:app, api_key: "sensitive-api-key")

    mcp_request("tools/call", {name: "errbit_get_app", arguments: {id: app.id}}, authorization: "Bearer #{token}")

    expect(json.dig("result", "structuredContent", "app")).to include("id" => app.id.to_s, "name" => app.name)
    expect(response.body).not_to include("sensitive-api-key")

    mcp_request("tools/call", {name: "errbit_get_app", arguments: {id: "missing"}}, authorization: "Bearer #{token}")

    expect(json.dig("result", "isError")).to be(true)
    expect(json.dig("result", "structuredContent", "error")).to eq("app_not_found")
  end

  it "returns a stable error for a malformed app ID" do
    mcp_request("tools/call", {name: "errbit_get_app", arguments: {id: "not/an/id"}}, authorization: "Bearer #{token}")

    expect(json.dig("result", "isError")).to be(true)
    expect(json.dig("result", "structuredContent")).to eq("error" => "app_not_found", "id" => "not/an/id")
  end

  it "does not mutate application or problem data" do
    app = create(:app)
    problem = create(:problem, app: app)
    app_attributes = app.reload.attributes
    problem_attributes = problem.reload.attributes
    app_count = App.count
    problem_count = Problem.count

    mcp_request("tools/call", {name: "errbit_list_apps", arguments: {}}, authorization: "Bearer #{token}")
    mcp_request("tools/call", {name: "errbit_get_app", arguments: {id: app.id}}, authorization: "Bearer #{token}")

    expect(App.count).to eq(app_count)
    expect(Problem.count).to eq(problem_count)
    expect(app.reload.attributes).to eq(app_attributes)
    expect(problem.reload.attributes).to eq(problem_attributes)
  end

  it "returns a stable tool error for invalid tool arguments" do
    mcp_request("tools/call", {name: "errbit_list_apps", arguments: {per_page: 101}}, authorization: "Bearer #{token}")

    expect(json.dig("result", "isError")).to be(true)
    expect(json.dig("result", "content", 0, "text")).to include("/per_page")
  end

  it "lists filtered, bounded problem metadata" do
    app = create(:app, name: "Problems app")
    create(:problem, app: app, environment: "production", message: "NoMethodError: missing value", resolved: false, last_notice_at: 2.hours.ago)
    create(:problem, app: app, environment: "production", message: "NoMethodError: resolved", resolved: true)
    create(:problem, app: app, environment: "staging", message: "NoMethodError: staging")
    create(:problem, environment: "production", message: "NoMethodError: another app")

    mcp_request(
      "tools/call",
      {
        name: "errbit_list_problems",
        arguments: {app_id: app.id, app_name: app.name, environment: "production", resolved: false, search: "NoMethodError", per_page: 1}
      },
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result.fetch("problems").size).to eq(1)
    expect(result.fetch("problems").first).to include(
      "app_id" => app.id.to_s,
      "app_name" => app.name,
      "environment" => "production",
      "resolved" => false
    )
    expect(result.fetch("per_page")).to eq(1)
    expect(result.fetch("total_count")).to eq(1)
  end

  it "returns deterministic incident facts and representative notice summaries" do
    app = create(:app, name: "Incident app")
    first = create(:problem, app: app, error_class: "TimeoutError", environment: "production", notices_count: 4, last_notice_at: 2.hours.ago)
    second = create(:problem, app: app, error_class: "TimeoutError", environment: "staging", notices_count: 2, last_notice_at: 1.hour.ago, resolved: true)
    err = create(:err, problem: second)
    notice = create(:notice, err: err, app: app, error_class: "TimeoutError")
    second.resolve!

    mcp_request(
      "tools/call",
      {name: "errbit_get_incident_summary", arguments: {app_name: "Incident app", limit: 1}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result).to include(
      "matching_problem_count" => 2,
      "total_notice_count" => 7,
      "resolved_problem_count" => 1,
      "unresolved_problem_count" => 1
    )
    expect(result.fetch("highest_frequency_problems").first.fetch("id")).to eq(first.id.to_s)
    expect(result.fetch("representative_latest_notices").first.fetch("id")).to eq(notice.id.to_s)
    expect(result.fetch("top_error_classes")).to eq([{"value" => "TimeoutError", "count" => 2}])
  end

  it "rejects an invalid incident summary date range" do
    mcp_request(
      "tools/call",
      {name: "errbit_get_incident_summary", arguments: {since: "2026-09-08T00:00:00Z", until: "2026-09-07T00:00:00Z"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "invalid_date_range")
  end

  it "returns setup guidance without app credentials" do
    app = create(:app, name: "Checkout", api_key: "sensitive-api-key")

    mcp_request(
      "tools/call",
      {name: "errbit_get_airbrake_setup_guidance", arguments: {app_id: app.id, framework: "ruby"}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result).to include("app" => {"id" => app.id.to_s, "name" => "Checkout"}, "project_id" => 1, "project_key" => "<ERRBIT_APP_API_KEY>")
    expect(result.fetch("snippets").keys).to eq(["ruby"])
    expect(response.body).not_to include("sensitive-api-key")
  end

  it "returns a stable error for an unknown setup guidance app" do
    mcp_request(
      "tools/call",
      {name: "errbit_get_airbrake_setup_guidance", arguments: {app_id: "missing"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "app_not_found", "app_id" => "missing")
  end

  it "rejects unsupported setup guidance frameworks" do
    mcp_request(
      "tools/call",
      {name: "errbit_get_airbrake_setup_guidance", arguments: {framework: "cobol"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "unsupported_framework", "framework" => "cobol")
  end

  it "orders problems by latest notice and then ID" do
    app = create(:app)
    timestamp = 1.hour.ago
    first_problem = create(:problem, app: app, last_notice_at: timestamp)
    second_problem = create(:problem, app: app, last_notice_at: timestamp)

    mcp_request(
      "tools/call",
      {name: "errbit_list_problems", arguments: {app_id: app.id, per_page: 100}},
      authorization: "Bearer #{token}"
    )

    ids = json.dig("result", "structuredContent", "problems").pluck("id")
    expect(ids.first(2)).to eq([first_problem.id.to_s, second_problem.id.to_s].sort.reverse)
  end

  it "returns an empty page when no problems match" do
    mcp_request(
      "tools/call",
      {name: "errbit_list_problems", arguments: {app_id: "missing-app"}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result.fetch("problems")).to eq([])
    expect(result.fetch("total_count")).to eq(0)
  end

  it "returns safe problem details and a stable error for an unknown problem" do
    app = create(:app, api_key: "sensitive-api-key")
    problem = create(
      :problem,
      app: app,
      message: "NoMethodError: missing value",
      issue_link: "https://issues.example.test/123",
      messages: {"secret" => {"value" => "request-password"}},
      hosts: {"secret" => {"value" => "internal.example.test"}}
    )

    mcp_request(
      "tools/call",
      {name: "errbit_get_problem", arguments: {id: problem.id}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent", "problem")
    expect(result).to include(
      "id" => problem.id.to_s,
      "app_id" => app.id.to_s,
      "message" => "NoMethodError: missing value",
      "issue_link" => "https://issues.example.test/123",
      "url" => problem.url
    )
    expect(response.body).not_to include("sensitive-api-key", "request-password", "internal.example.test")

    mcp_request(
      "tools/call",
      {name: "errbit_get_problem", arguments: {id: "missing"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "isError")).to be(true)
    expect(json.dig("result", "structuredContent")).to eq("error" => "problem_not_found", "id" => "missing")
  end

  it "returns a stable error for a malformed problem ID" do
    mcp_request(
      "tools/call",
      {name: "errbit_get_problem", arguments: {id: "not/an/id"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "isError")).to be(true)
    expect(json.dig("result", "structuredContent")).to eq("error" => "problem_not_found", "id" => "not/an/id")
  end

  it "returns the complete persisted latest notice context" do
    app = create(:app)
    problem = create(:problem, app: app)
    notice = create(
      :notice,
      app: app,
      err: create(:err, problem: problem),
      message: "NoMethodError: missing value",
      request: {"url" => "https://example.test/orders?token=stored-value", "params" => {"order_id" => "42"}},
      server_environment: {"environment-name" => "production", "app-version" => "2026.09.07"},
      notifier: {"name" => "custom-notifier", "version" => "1"},
      user_attributes: {"account_id" => "account-42"}
    )

    mcp_request(
      "tools/call",
      {name: "errbit_get_latest_notice", arguments: {problem_id: problem.id}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent", "notice")
    expect(result).to include(
      "id" => notice.id.to_s,
      "problem_id" => problem.id.to_s,
      "message" => notice.message,
      "request" => hash_including("url" => "https://example.test/orders?token=stored-value"),
      "server_environment" => hash_including("app-version" => "2026.09.07"),
      "notifier" => hash_including("name" => "custom-notifier"),
      "user_attributes" => hash_including("account_id" => "account-42"),
      "backtrace" => JSON.parse(notice.backtrace.lines.to_json)
    )
  end

  it "returns stable errors for missing notices and oversized notices" do
    problem = create(:problem)

    mcp_request(
      "tools/call",
      {name: "errbit_get_latest_notice", arguments: {problem_id: problem.id}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "notice_not_found", "problem_id" => problem.id.to_s)

    notice = create(:notice, request: {"payload" => "x" * 1_000_001})
    mcp_request(
      "tools/call",
      {name: "errbit_get_latest_notice", arguments: {problem_id: notice.problem.id}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "notice_too_large", "max_bytes" => 1_000_000)
    expect(response.body).not_to include("x" * 1_000)
  end

  it "returns one persisted notice by ID with bounded troubleshooting context" do
    app = create(:app)
    problem = create(:problem, app: app)
    notice = create(:notice, app: app, err: create(:err, problem: problem))

    mcp_request(
      "tools/call",
      {name: "errbit_get_notice", arguments: {id: notice.id}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent", "notice")
    expect(result).to include("id" => notice.id.to_s, "problem_id" => problem.id.to_s, "problem" => hash_including("id" => problem.id.to_s), "app" => hash_including("id" => app.id.to_s))
    expect(result).to include("request", "server_environment", "notifier", "backtrace")
  end

  it "returns a stable error for an unknown notice ID" do
    mcp_request(
      "tools/call",
      {name: "errbit_get_notice", arguments: {id: "missing"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "notice_not_found", "id" => "missing")
  end

  it "lists notices across apps with bounded filters" do
    matching_app = create(:app, name: "Checkout")
    other_app = create(:app, name: "Billing")
    matching_problem = create(:problem, app: matching_app, environment: "production", resolved: false)
    other_problem = create(:problem, app: other_app, environment: "production", resolved: false)
    matching_notice = create(:notice, app: matching_app, err: create(:err, problem: matching_problem), message: "Checkout timeout")
    create(:notice, app: other_app, err: create(:err, problem: other_problem), message: "Billing timeout")

    mcp_request(
      "tools/call",
      {name: "errbit_list_notices", arguments: {app_name: "Checkout", environment: "production", resolved: false, search: "Checkout"}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result.fetch("notices").map { |notice| notice.fetch("id") }).to eq([matching_notice.id.to_s])
    expect(result.fetch("notices").first).to include("problem_id" => matching_problem.id.to_s)
  end

  it "rejects an unscoped notice list" do
    mcp_request(
      "tools/call",
      {name: "errbit_list_notices", arguments: {}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "invalid_filters")
  end

  it "lists newest notice summaries with pagination and no raw context" do
    problem = create(:problem)
    err = create(:err, problem: problem)
    first_notice = create(
      :notice,
      err: err,
      created_at: 2.hours.ago,
      request: {"url" => "https://example.test/old?token=secret-value"}
    )
    second_notice = create(
      :notice,
      err: err,
      created_at: 1.hour.ago,
      message: "m" * 600,
      error_class: "e" * 600,
      framework: "f" * 600,
      server_environment: {"environment-name" => "n" * 600, "app-version" => "v" * 600},
      request: {"url" => "https://example.test/new?token=secret-value", "component" => "c" * 600}
    )

    mcp_request(
      "tools/call",
      {name: "errbit_list_notices", arguments: {problem_id: problem.id, page: 1, per_page: 1}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result.fetch("notices").map { |notice| notice.fetch("id") }).to eq([second_notice.id.to_s])
    expect(result.fetch("total_count")).to eq(2)
    expect(result.fetch("total_pages")).to eq(2)
    summary = result.fetch("notices").first
    expect(summary.slice("message", "error_class", "framework", "environment", "app_version", "where").values.map(&:length)).to all(eq(500))
    expect(response.body).not_to include("secret-value")

    mcp_request(
      "tools/call",
      {name: "errbit_list_notices", arguments: {problem_id: problem.id, page: 2, per_page: 1}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent", "notices").map { |notice| notice.fetch("id") }).to eq([first_notice.id.to_s])
  end

  it "returns an empty notice page and a stable error for an unknown problem" do
    problem = create(:problem)

    mcp_request(
      "tools/call",
      {name: "errbit_list_notices", arguments: {problem_id: problem.id}},
      authorization: "Bearer #{token}"
    )

    result = json.dig("result", "structuredContent")
    expect(result.fetch("notices")).to eq([])
    expect(result.fetch("total_count")).to eq(0)

    mcp_request(
      "tools/call",
      {name: "errbit_list_notices", arguments: {problem_id: "missing"}},
      authorization: "Bearer #{token}"
    )

    expect(json.dig("result", "structuredContent")).to eq("error" => "problem_not_found", "problem_id" => "missing")
  end

  private

  def mcp_request(method, params = {}, authorization:, headers: {}, payload: nil)
    request_headers = self.headers.merge(headers)
    request_headers["Authorization"] = authorization if authorization
    payload ||= {jsonrpc: "2.0", id: 1, method: method, params: params}.to_json
    post "/mcp", params: payload, headers: request_headers
  end

  def json
    response.parsed_body
  end
end
