# Configuring Errbit
Following the recommendation of [12factor.net](http://12factor.net/config),
Errbit takes all of its configuration from environment variables. You can use
[dotenv](https://github.com/bkeepers/dotenv), which is included in the Gemfile,
to fill in any values that you can't or won't supply through the environment.

In order of precedence Errbit uses:
1. Environment variables (for example MY_VALUE=abc bundle exec unicorn)
2. Values provided in a .env file
3. Default values from .env.default

## Configuration Parameters
Variable Name              | Default            | Description
-------------------------- | ------------------ | -----------
ERRBIT_HOST                | errbit.example.com | Hostname to use when building links back to Errbit
ERRBIT_PROTOCOL            | http               | Protocol to use when building links back to Errbit (http or https)
ERRBIT_PORT                | No default         | TCP port to use when building links back to Errbit
ERRBIT_ENFORCE_SSL         | false              | When enabled, Errbit forces all traffic over https
ERRBIT_CONFIRM_ERR_ACTIONS | true               | Present confirmation dialogs when users act on errors
ERRBIT_USER_HAS_USERNAME   | true               | Allow users to have a username field
ERRBIT_USE_GRAVATAR        | true               | Enable gravatars
ERRBIT_GRAVATAR_DEFAULT    | identicon          | Default gravatar image (see https://en.gravatar.com/site/implement/images/)
SERVE_STATIC_ASSETS        | true               | Allow Rails to serve static assets. For most production environments, this should be false because your web server should be configured to serve static assets for you. But some environments like Heroku require this to be true.
SECRET_KEY_BASE            | insecure_string    | For production environments, you should run `rake secret` to generate a secret, unique key for this parameter
