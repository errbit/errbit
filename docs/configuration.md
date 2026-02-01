# Configuring Errbit

Following the recommendation of [12factor.net](https://12factor.net/config),
Errbit takes all of its configuration from environment variables.

In order of precedence Errbit uses:

1. Environment variables (for example `MY_VALUE=abc bundle exec puma`)
2. Values provided in a `config/errbit.yml` file

## Configuration Parameters

### Build-in Ruby on Rails environment variables

#### `RAILS_ENV`

Environment. Can be `production`, `development`, or `test`.

Use `production` for run production Errbit. This is the default in the
container.

#### `SECRET_KEY_BASE`

Generate with `rails secret`. Changing it will break all active browser sessions.

| Environment variable | Description       | Default       | Default in container |
|----------------------|-------------------|---------------|----------------------|
| `PORT`               | Port              | `3000`        | as default           |
| `RAILS_MAX_THREADS`  | Rails max threads | `3`           | as default           |
| `WEB_CONCURRENCY`    | Number of CPU     | not set       | not set              |
| `RAILS_LOG_LEVEL`    | Log level         | `info`        | `info`               |

### Thruster environment variables

#### `THRUSTER_TLS_DOMAIN`

Domain name to get certificate e.g. `errbit.example.com`

Default: not set

You can look more about thruster env's [here](https://github.com/basecamp/thruster).

### rack-timeout environment variables

[Here](./rack-timeout.md).

### Application environment variables

#### `MONGO_URL`

URL connection string for mongo in the form `mongodb://username:password@example.com:port`.
To more easily set up connections to third party mongo providers, you can call
this value `MONGODB_URI`, `MONGOLAB_URI`, `MONGOHQ_URL`, `MONGODB_URL` or `MONGO_URL`.

Default: `mongodb://localhost/errbit_<Rails.env>` e.g.
`mongodb://localhost/errbit_development` for development environment.

#### `ERRBIT_HOST`

Hostname to use when building links back to Errbit.

Default: `errbit.example.com`

Default in container: as default.

#### `ERRBIT_ADMIN_EMAIL`

E-Mail address of initial admin user.

Default: `errbit@errbit.example.com`

Default in container: `errbit@errbit.example.com`

#### `ERRBIT_ADMIN_USER`

Username of initial admin user.

Default: `errbit`

Default in container: as default.

#### `ERRBIT_ADMIN_PASSWORD`

Password of initial admin user.

Default: some random string (see output of `$ bundle exec rails db:seed`)

#### `ERRBIT_CONFIRM_ERR_ACTIONS`

Present confirmation dialogs when users act on errors.

Default: `true`

Default in container: as default.


| Environment variable         | Description  | Default  | Default in container |
|------------------------------|--------------|----------|----------------------|
| `MONGO_URL`                  |              |          |                      |
| `ERRBIT_USER_HAS_USERNAME`   |              |          |                      |
| `ERRBIT_USE_GRAVATAR`        |              |          |                      |
| `ERRBIT_GRAVATAR_DEFAULT`    |              |          |                      |
| `ERRBIT_EMAIL_FROM`          |              |          |                      |

### GitHub

#### 

<dl>
<dt>ERRBIT_USER_HAS_USERNAME
<dd>Allow users to have a username field
<dd>defaults to false
<dt>ERRBIT_USE_GRAVATAR
<dd>Enable gravatar
<dd>defaults to true
<dt>ERRBIT_GRAVATAR_DEFAULT
<dd>Default gravatar image (see https://en.gravatar.com/site/implement/images/)
<dd>identicon
<dt>ERRBIT_EMAIL_FROM
<dd>The value that should be set in the 'from' field for outgoing emails
<dd>defaults to errbit@example.com
<dt>ERRBIT_EMAIL_AT_NOTICES
<dd>Errbit notifies watchers via email after the set number of occurrences of the same error. [0] means notify on every occurrence.
<dd>defaults to [1,10,100]
<dt>ERRBIT_PER_APP_EMAIL_AT_NOTICES
<dd>Let every application have its own configuration rather than using `ERRBIT_EMAIL_AT_NOTICES`. If this value is true, you can configure each app using the web UI.
<dd>defaults to false
<dt>ERRBIT_NOTIFY_AT_NOTICES
<dd>Notify each application's configured notification service after the set number of occurrences of the same error. [0] means notify on every occurrence.
<dd>defaults to [0]
<dt>ERRBIT_PER_APP_NOTIFY_AT_NOTICES
<dd>Let every application have its own configuration rather than using `ERRBIT_NOTIFY_AT_NOTICES`. If this value is set to true, you can configure each app using the web UI.
<dd>defaults to false
<dt>ERRBIT_PROBLEM_DESTROY_AFTER_DAYS
<dd>Number of days to keep errors in the database when running `bundle exec rails errbit:clear_outdated`
<dd>defaults to nil (off)
<dt>SECRET_KEY_BASE
<dd>For production environments, you should run `bundle exec rails secret` to generate a secret, unique key for this parameter
<dd>defaults to f258ed69266dc8ad0ca79363c3d2f945c388a9c5920fc9a1ae99a98fbb619f135001c6434849b625884a9405a60cd3d50fc3e3b07ecd38cbed7406a4fccdb59c
<dt>GITHUB_URL
<dd>Use this URL for interacting GitHub. This is useful if you have a GitHub enterprise account and you're using a URL other than https://github.com
<dd>defaults to https://github.com
<dt>GITHUB_API_URL</dt>
<dd>For GitHub enterprise accounts, the API URL could be something like https://github.example.com/api/v3</dd>
<dd>defaults to https://api.github.com</dd>
<dt>GITHUB_AUTHENTICATION
<dd>Allow GitHub sign-in via OAuth
<dd>defaults to true
<dt>GITHUB_CLIENT_ID
<dd>Client id of your GitHub application
<dt>GITHUB_SECRET
<dd>Secret key for your GitHub application
<dt>GITHUB_ORG_ID
<dd>ID of your GitHub organization. If set, Errbit will create user accounts for users in your GitHub organization who sign into Errbit without having a user account
<dt>GITHUB_ACCESS_SCOPE
<dd>OAuth scope to request from users when they sign in through GitHub
<dd>defaults to [repo]
<dt>GITHUB_SITE_TITLE</dt>
<dd>The title to use for GitHub. This value is whatever you want displayed in the Errbit UI when referring to GitHub.</dd>
<dd>defaults to GitHub</dd>
<dt>GOOGLE_AUTHENTICATION
<dd>Allow google sign-in via OAuth
<dd>defaults to true
<dt>GOOGLE_AUTO_PROVISION
<dd>Allow automatic account creation after sign-in via OAuth
<dt>GOOGLE_CLIENT_ID
<dd>Client id of your google application
<dt>GOOGLE_SECRET
<dd>Secret key for your google application
<dt>GOOGLE_REDIRECT_URI
<dd>The redirect URI for your application (useful if you want to redirect using HTTPS)
<dd>defaults to the HTTP location of ERRBIT_HOST
<dt>GOOGLE_AUTHORIZED_DOMAINS
<dd>A comma-delimited list of account domains that are permitted to sign-in (recommended to set when GOOGLE_AUTO_PROVISION is set to true)
<dt>GOOGLE_SITE_TITLE</dt>
<dd>The title to use for Google. This value is whatever you want displayed in the Errbit UI when referring to Google.</dd>
<dd>defaults to Google</dd>
<dt>EMAIL_DELIVERY_METHOD
<dd>:smtp or :sendmail, depending on how you want Errbit to send email
<dt>SMTP_SERVER
<dd>Server address for outgoing SMTP messages
<dt>SMTP_PORT
<dd>Server port for outgoing SMTP messages
<dt>SMTP_AUTHENTICATION
<dd>Authentication method for the SMTP connection (see http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration)
<dt>SMTP_USERNAME
<dd>Username for SMTP auth, you could also set SENDGRID_USERNAME
<dt>SMTP_PASSWORD
<dd>Password for SMTP auth, you could also set SENDGRID_PASSWORD
<dt>SMTP_DOMAIN
<dd>HELO domain to set for outgoing SMTP messages, you can also use SENDGRID_DOMAIN
<dt>SMTP_ENABLE_STARTTLS_AUTO
<dd>Detects if STARTTLS is enabled in your SMTP server and starts to use it
<dt>SMTP_OPENSSL_VERIFY_MODE
<dd>When using TLS, you can set how OpenSSL checks the certificate. This is really useful if you need to validate a self-signed and/or a wildcard certificate. You can use the name of an OpenSSL verify constant ('none', 'peer', 'client_once', 'fail_if_no_peer_cert').
<dt>SENDMAIL_LOCATION
<dd>Path to sendmail
<dt>SENDMAIL_ARGUMENTS
<dd>Custom arguments for sendmail
<dt>DEVISE_MODULES
<dd>Devise modules to enable
<dd>defaults to [database_authenticatable,recoverable,rememberable,trackable,validatable,omniauthable]
</dl>
