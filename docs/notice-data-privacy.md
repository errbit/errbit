# Protecting Notice Data

Configure the application sending errors to remove secrets before they reach
Errbit. Errbit's server-side sanitization is defense in depth, not a substitute
for application-level filtering.

## Rails And Airbrake

Configure Rails parameter filtering with every sensitive field used by the
application:

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += %i[
  password
  password_confirmation
  token
  api_key
  authorization
  cookie
  csrf_token
]
```

For Airbrake Ruby, pass the Rails filter list to Airbrake's blocklist. Check the
Airbrake documentation for the gem version used by the application.

```ruby
# config/initializers/airbrake.rb
Airbrake.configure do |config|
  config.blocklist_keys = Rails.application.config.filter_parameters
end
```

Add application-specific sensitive fields, such as payment tokens or customer
identifiers, to `filter_parameters`. When that list is assigned to Airbrake's
`blocklist_keys`, the same policy is applied before notices are transmitted. Do
not enable request-body capture unless the application has independently filtered
its body data; request bodies often contain credentials.

## Errbit Server-Side Sanitization

Errbit sanitizes V3 notice data before storing it by default:

```text
ERRBIT_SANITIZE_NOTICE_DATA=true
```

When enabled, Errbit replaces sensitive-looking values and configured custom
values with `[FILTERED]`. Framework-internal CGI data is removed, while
sensitive headers and query parameters retain their names with filtered values.
URL credentials and fragments are removed. Errbit also recursively sanitizes
request parameters, session values, server environment data, notifier data, and
user attributes.

`request["session"]` is treated as a container. Non-sensitive session values are
retained, while sensitive leaves such as `csrf_token`, `access_token`, and
`password` are replaced with `[FILTERED]`.

Errbit intentionally uses broad fail-closed built-in key matching. Some benign
diagnostic values whose key names resemble sensitive terms may be replaced with
`[FILTERED]`. This favors preventing secret persistence over retaining every
diagnostic value.

Add literal case-insensitive custom key names with a comma-separated value:

```text
ERRBIT_SENSITIVE_KEYS=customer_ssn,private_id,internal_auth
```

Custom keys augment Errbit's built-in filtering; they never replace it.

Set `ERRBIT_SANITIZE_NOTICE_DATA=false` only for a temporary compatibility need.
It retains legacy notice data where storage safety permits, including sessions,
CGI internals, and URL/query data. MongoDB key escaping and invalid-string
protection remain enabled, but sensitive data may be persisted. The
`[FILTERED]` replacement is only used when privacy sanitization is enabled.

## App-Level Override

Administrators can override the global setting when editing an app. Each app can
inherit the global value, always sanitize notice data, or disable sanitization for
newly ingested notices. An explicit app setting takes precedence over
`ERRBIT_SANITIZE_NOTICE_DATA`, so an app set to always sanitize is protected even
when the global setting is `false`.

The override does not change historical notices. The historical scrubber always
sanitizes the notices it processes, regardless of the global or app-level setting.

## Demo Verification

Run `bin/rails errbit:demo` in a non-production database to create a demo notice
with fake sensitive values in parameters, sessions, headers, URLs, query strings,
server environment data, notifier data, and user attributes. With
`ERRBIT_SANITIZE_NOTICE_DATA=true`, inspect the latest demo notice and verify
that sensitive values display as `[FILTERED]`, while safe values remain visible.
Framework-internal CGI values and URL credentials/fragments are removed.

## Scrubbing Historical Notices

Ingestion sanitization does not modify notices already stored in MongoDB. Back up
the database first and, for large installations, run the historical scrubber
during a maintenance or low-traffic window. It performs a dry run by default:

```sh
bin/rails errbit:sanitize_historical_notices
```

Review the reported counts, then apply the scrub with the exact write flag
`DRY_RUN=false`:

```sh
DRY_RUN=false BATCH_SIZE=500 bin/rails errbit:sanitize_historical_notices
```

Use `LIMIT` to process a bounded number of notices during a trial run. The task
forces privacy sanitization on, is safe to rerun, updates notices without
touching timestamps, and reports failures without printing notice contents. It
sanitizes the same four notice fields as ingestion: `request`,
`server_environment`, `notifier`, and `user_attributes`. It does not sanitize
`message` or `backtrace`.
