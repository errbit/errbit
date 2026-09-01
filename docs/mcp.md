# Errbit MCP Server

Errbit provides a Model Context Protocol (MCP) endpoint for server-to-server
clients that currently exposes read-only tools. It is disabled by default.

## Enablement

Set both variables and restart Errbit:

```sh
ERRBIT_MCP_SERVER=true
ERRBIT_MCP_AUTH_TOKEN=replace-with-a-long-random-token
```

Every request to `https://errbit.example.com/mcp` must send the configured token
in an `Authorization: Bearer` header. This token is separate from application
ingestion API keys. Rotate it by changing `ERRBIT_MCP_AUTH_TOKEN` and restarting
all Errbit processes.

Do not expose the endpoint publicly without TLS and a strong token. The single
deployment-wide bearer credential has global visibility of Errbit data. The
current server only exposes read-only tools; browser clients and CORS are not
supported.

The SDK validates the request `Host` header to prevent DNS rebinding.
`ERRBIT_MCP_ALLOWED_HOSTS` is optional: when it is omitted or empty, it defaults
to `ERRBIT_HOST`. A standard deployment using
`ERRBIT_HOST=errbit.example.com` therefore needs no additional MCP host
configuration.

Set `ERRBIT_MCP_ALLOWED_HOSTS` only when a reverse proxy presents a different
host, or when using an IP address or custom port. It accepts a comma-separated
list of hosts. A bare host permits every port; include `host:port` to permit
only that port. Leaving it empty does not disable Host validation.

The first release uses one deployment-wide bearer principal. It is not mapped to
an Errbit `User`, does not provide per-user authorization, and is not an app
ingestion credential. Future per-user or scoped access requires a new
authentication design rather than passing this token into individual tools.

## Clients

Configure Streamable HTTP clients with the endpoint URL and bearer token. For
example, an OpenCode MCP configuration uses:

```json
{
  "type": "remote",
  "url": "https://errbit.example.com/mcp",
  "headers": {"Authorization": "Bearer replace-with-a-long-random-token"}
}
```

Cursor, Claude, and other Streamable HTTP clients use the same URL and header.

## Tools and limits

- `errbit_list_apps`: lists applications ordered by name. It accepts an optional
  case-insensitive substring `search` against app names, defaults to 25 results,
  and accepts `page` and `per_page`; `per_page` is capped at 100. Organization
  filtering is not supported because Errbit has no app ownership model.
- `errbit_get_app`: returns safe application metadata and problem counts for an
  application ID.
- `errbit_list_problems`: lists bounded problem summaries. It accepts optional
  exact `app_id` and cached `app_name`, exact `environment`, `resolved`, and
  existing MongoDB full-text `search` filters, plus `page` and `per_page`;
  `per_page` is capped at 100. Full-text search covers the indexed problem
  fields and also accepts an exact notice ID. Results are ordered by latest
  notice time and then ID.
- `errbit_get_problem`: returns safe details for a problem ID, including its
  Errbit URL and configured issue link when present.
- `errbit_get_latest_notice`: returns the latest persisted notice for a problem,
  including request, environment, notifier, user, and complete backtrace data.
  The payload is rejected when it exceeds 1 MB rather than silently dropping
  troubleshooting fields.
- `errbit_get_notice`: returns the same bounded persisted troubleshooting context
  for one notice ID, allowing agents to inspect a specific occurrence after
  `errbit_list_notices`.
- `errbit_list_notices`: lists notice summaries newest first. It accepts the
  existing `problem_id` filter or bounded cross-app filters for `app_id`,
  `app_name`, `environment`, `resolved`, and notice message/error-class
  `search`, plus `page` and `per_page`; `per_page` is capped at 100. At least
  one filter is required. Use `errbit_get_notice` or
  `errbit_get_latest_notice` when full persisted context is needed.
- `errbit_get_incident_summary`: returns deterministic counts, resolved-state
  totals, latest affected problems, highest-frequency problems, top error
  classes, top environments, and representative latest notice summaries.
  It accepts the same app/problem filters plus ISO 8601 `since`, `until`, and a
  `limit` capped at 25. Date filters select problems whose recorded activity
  overlaps the range; notice totals and frequency use cached problem counters.
- `errbit_get_airbrake_setup_guidance`: returns placeholder-only setup snippets
  for Ruby, Node, Python, and Go. With an optional Errbit `app_id`, it resolves
  and returns only that app's ID and name. It also accepts a `framework` filter.
  It never reads or returns an app API key; users must copy that key from the
  app settings. See the supported
  [Airbrake client documentation](https://docs.airbrake.io/docs/platforms/ruby/)
  for the selected client version.

All tool responses include structured JSON and text JSON for older clients.
Application API keys and embedded app integration configuration are never
included in app responses. Latest-notice data follows the persisted notice
sanitization setting: disabling sanitization can expose raw credentials and
private request data to the MCP bearer principal.

The endpoint uses stateless Streamable HTTP. It supports simple request/response
calls only, does not retain sessions, and does not provide subscription streams.

## Operations

The endpoint has no application-level rate limiter. Put it behind the same
trusted reverse proxy or gateway used for Errbit and apply deployment-level
request throttling and a maximum `/mcp` request body of 1 MB there. MCP does not
accept file uploads, and the gateway must reject oversized requests before they
reach Rails. MCP requests use Errbit's existing Rack timeout; slow MongoDB
queries are not given a separate MCP timeout.

The bearer token is not an application user credential and must not be written
to request logs. The endpoint is stateless, so it does not require session
affinity. When disabled, `/mcp` returns `404`; when enabled in production
without a token, Errbit refuses to boot. Latest-notice responses are rejected
above 1 MB rather than truncated. Their persisted fields follow the configured
notice-sanitization setting, so disabling sanitization can expose private data
to the bearer principal. Unexpected MCP failures return a generic `500` response
with error code `mcp_internal_error` and the request ID; exception messages and
notice payloads are not returned or logged.

The endpoint accepts `POST` requests with JSON content and the MCP protocol
version `2025-03-26`. Other HTTP methods or media types are rejected by the
transport.
