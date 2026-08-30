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
diagnostic keys whose names resemble sensitive terms may be omitted. This favors
preventing secret persistence over retaining every diagnostic field.

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

## Demo Verification

Run `bin/rails errbit:demo` in a non-production database to create a demo notice
with fake sensitive values in parameters, sessions, headers, URLs, query strings,
server environment data, notifier data, and user attributes. With
`ERRBIT_SANITIZE_NOTICE_DATA=true`, inspect the latest demo notice and verify
that sensitive values display as `[FILTERED]`, while safe values remain visible.
Framework-internal CGI values and URL credentials/fragments are removed.
