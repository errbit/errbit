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
Variable Name                    | Default             | Description
-------------------------------- | ------------------- | -----------
ERRBIT_HOST                      | errbit.example.com  | Hostname to use when building links back to Errbit
ERRBIT_PROTOCOL                  | http                | Protocol to use when building links back to Errbit (http or https)
ERRBIT_PORT                      | _No default_        | TCP port to use when building links back to Errbit
ERRBIT_ENFORCE_SSL               | false               | When enabled, Errbit forces all traffic over https
ERRBIT_CONFIRM_ERR_ACTIONS       | true                | Present confirmation dialogs when users act on errors
ERRBIT_USER_HAS_USERNAME         | true                | Allow users to have a username field
ERRBIT_USE_GRAVATAR              | true                | Enable gravatars
ERRBIT_GRAVATAR_DEFAULT          | identicon           | Default gravatar image (see https://en.gravatar.com/site/implement/images/)
ERRBIT_EMAIL_FROM                | errbit@example.com  | The value that should be set in the 'from' field for outgoing emails
ERRBIT_EMAIL_AT_NOTICES          | [1,10,100]          | Errbit notifies watchers via email after the set number of occurances of the same error
ERRBIT_PER_APP_EMAIL_AT_NOTICES  | false               | Let every application have it's own configuration rather than using ERRBIT_EMAIL_AT_NOTICES. If this value is true, you can configure each app using the web UI.
ERRBIT_NOTIFY_AT_NOTICES         | [0]                 | Notify each application's configured notification service after the set number of occurances of the same error. [0] means notify on every occurance.
ERRBIT_PER_APP_NOTIFY_AT_NOTICES | false               | Let every application have it's own configuration rather than using ERRBIT_NOTIFY_AT_NOTICES. If this value is set to true, you can configure each app using the web UI.
SERVE_STATIC_ASSETS              | true                | Allow Rails to serve static assets. For most production environments, this should be false because your web server should be configured to serve static assets for you. But some environments like Heroku require this to be true.
SECRET_KEY_BASE                  | insecure-string     | For production environments, you should run `rake secret` to generate a secret, unique key for this parameter
MONGO_URL                        | mongodb://localhost | URL connection string for mongo in the form mongodb://username:password@example.com:port To more easily set up connections to third party mongo providers, you can call this value MONGOLAB_URI, MONGOHQ_URL, MONGODB_URL or MONGO_URL
GITHUB_URL                       | https://github.com  | Use this URL for interacting github. This is useful if you have a github enterprise account and you're using a URL other than https://github.com
GITHUB_AUTHENTICATION            | true                | Allow github sign-in via OAuth
GITHUB_CLIENT_ID                 | _No default_        | Client id of your github application
GITHUB_SECRET                    | _No default_        | Secret key for your github application
GITHUB_ORG_ID                    | _No default_        | ID of your github organization. If set, Errbit will create user accounts for users in your github organization who sign into Errbit without having a user account
GITHUB_ACCESS_SCOPE              | [repo]              | OAuth scope to request from users when they sign-in through github
EMAIL_DELIVERY_METHOD            | sendmail            | SMTP or sendmail, depending on how you want Errbit to send email
SMTP_SERVER                      | _No default_        | Server address for outgoing SMTP messages
SMTP_PORT                        | _No default_        | Server port for outgoing SMTP messages
SMTP_AUTHENTICATION              | _No default_        | Authentication method for the SMTP connection (see http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration)
SMTP_USERNAME                    | _No default_        | Username for SMTP auth, you could also set SENDGRID_USERNAME
SMTP_PASSWORD                    | _No default_        | Password for SMTP auth, you could also set SENDGRID_PASSWORD
SMTP_DOMAIN                      | _No default_        | HELO domain to set for outgoing SMTP messages, you can also use SENDGRID_DOMAIN
SENDMAIL_LOCATION                | _No defalut_        | Path to sendmail
SENDMAIL_ARGUMENTS               | _No default_        | Custom arguments for sendmail
DEVISE_MODULES                   | [database_authenticatable,recoverable,rememberable,trackable,validatable,omniauthable] | Devise modules to enable
