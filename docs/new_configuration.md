# Configuring Errbit

Following the recommendation of [12factor.net](https://12factor.net/config),
Errbit can take all of its configuration from environment variables or
from a TOML configuration file `config/errbit.toml`.

In order of precedence Errbit uses:

1. Environment variables (for example MY_VALUE=abc bundle exec puma)
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

### rack-timeout parameters

[Here](./rack-timeout.md).

### Application parameters

#### Base parameters

