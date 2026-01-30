# Configuring Errbit

Following the recommendation of [12factor.net](https://12factor.net/config),
Errbit can take all of its configuration from environment variables and/or
from a TOML configuration file `config/errbit.toml`.

In order of precedence Errbit uses:

1. Environment variables (for example `MY_VALUE=abc bundle exec puma`)
2. Default values from `config/errbit.toml` file

## Configuration Parameters

### Build-in Ruby on Rails parameters

| Environment variable       | Description       | Default       | Default in container |
|----------------------------|-------------------|---------------|----------------------|
| `RAILS_ENV`                | Environment       | `development` | `production`         |
| `PORT`                     | Port              | `3000`        | as default           |
| `RAILS_MAX_THREADS`        | Rails max threads | `3`           | as default           |
| `WEB_CONCURRENCY`          | Number of CPU     | not set       | not set              |
| `RAILS_LOG_LEVEL`          | Log level         | `info`        | `info`               |
| `SECRET_KEY_BASE`          | Secret key base   | not set       | not set              |

### Thruster parameters

| Environment variable  | Description                                              |
|-----------------------|----------------------------------------------------------|
| `THRUSTER_TLS_DOMAIN` | Domain name to get certificate e.g. `errbit.example.com` |

You can look more about thruster env's [here](https://github.com/basecamp/thruster).

### `rack-timeout` parameters

[rack-timeout defaults in Errbit](./rack-timeout.md).

### Application parameters

#### Base parameters

This is part of the default configuration:

```toml
[errbit]
host = "errbit.example.com" # Mapped as `ERRBIT_HOST` env variable. String.
user_has_username = false # Mapped as `ERRBIT_USER_HAS_USERNAME` env variable. String: "true" or "false".
mongo_url = "mongodb://localhost" # Mapped as ERRBIT_MONGO_URL env variable. String.
confirm_err_actions = true
confirm_resolve_err = true
per_app_notify_at_notices = false
per_app_email_at_notices = false
email_at_notices = [1, 10, 100]
notify_at_notices = [0]
devise_modules = ["database_authenticatable", "recoverable", "rememberable", "trackable", "validatable", "omniauthable"]
log_location = "STDOUT"
notice_deprecation_days = 7
```

Any options can be overridden by environment variables. See a comment for each env on each line how to override it.

##### `ERRBIT_HOST`

Hostname to use when building links back to Errbit.

Default: `errbit.example.com`
Default in container: as default

##### `ERRBIT_USER_HAS_USERNAME`

Allow users to have a username field.

Default: `false`
Default in container: as default
