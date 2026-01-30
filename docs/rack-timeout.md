# Configuring `rack-timeout` gem

| ENV                              | Default | Default in container |
|----------------------------------|---------|----------------------|
| `RACK_TIMEOUT_SERVICE_TIMEOUT`   | 15      | as default           |
| `RACK_TIMEOUT_WAIT_TIMEOUT`      | 30      | as default           |
| `RACK_TIMEOUT_WAIT_OVERTIME`     | 60      | as default           |
| `RACK_TIMEOUT_SERVICE_PAST_WAIT` | false   | as default           |
| `RACK_TIMEOUT_TERM_ON_TIMEOUT`   | 0       | as default           |

For more information, refer to [rack-timeout documentation](https://github.com/zombocom/rack-timeout).
