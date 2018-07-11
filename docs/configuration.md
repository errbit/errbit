# Configuring Errbit
Following the recommendation of [12factor.net](http://12factor.net/config),
Errbit takes all of its configuration from environment variables. You can use
[dotenv](https://github.com/bkeepers/dotenv), which is included in the Gemfile,
to fill in any values that you can't or won't supply through the environment.

In order of precedence Errbit uses:
1. Environment variables (for example MY_VALUE=abc bundle exec puma)
2. Values provided in a .env file
3. Default values from .env.default

## Configuration Parameters
<dl>
<dt>ERRBIT_HOST
<dd>Hostname to use when building links back to Errbit
<dd>defaults to errbit.example.com
<dt>ERRBIT_PROTOCOL
<dd>Protocol to use when building links back to Errbit (http or https)
<dd>defaults to http
<dt>ERRBIT_PORT
<dd>TCP port to use when building links back to Errbit
<dt>ERRBIT_ENFORCE_SSL
<dd>When enabled, Errbit forces all traffic over https
<dd>defaults to false
<dt>ERRBIT_CONFIRM_ERR_ACTIONS
<dd>Present confirmation dialogs when users act on errors
<dd>defaults to true
<dt>ERRBIT_USER_HAS_USERNAME
<dd>Allow users to have a username field
<dd>defaults to true
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
<dd>Errbit notifies watchers via email after the set number of occurances of the same error. [0] means notify on every occurance.
<dd>defaults to [1,10,100]
<dt>ERRBIT_PER_APP_EMAIL_AT_NOTICES
<dd>Let every application have it's own configuration rather than using ERRBIT_EMAIL_AT_NOTICES. If this value is true, you can configure each app using the web UI.
<dd>defaults to false
<dt>ERRBIT_NOTIFY_AT_NOTICES
<dd>Notify each application's configured notification service after the set number of occurances of the same error. [0] means notify on every occurance.
<dd>defaults to [0]
<dt>ERRBIT_PER_APP_NOTIFY_AT_NOTICES
<dd>Let every application have it's own configuration rather than using ERRBIT_NOTIFY_AT_NOTICES. If this value is set to true, you can configure each app using the web UI.
<dd>defaults to false
<dt>ERRBIT_PROBLEM_DESTROY_AFTER_DAYS
<dd>Number of days to keep errors in the database when running rake errbit:clear_outdated
<dd>defaults to nil (off)
<dt>SERVE_STATIC_ASSETS
<dd>Allow Rails to serve static assets. For most production environments, this should be false because your web server should be configured to serve static assets for you. But some environments like Heroku require this to be true.
<dd>defaults to true
<dt>SECRET_KEY_BASE
<dd>For production environments, you should run `rake secret` to generate a secret, unique key for this parameter
<dd>defaults to f258ed69266dc8ad0ca79363c3d2f945c388a9c5920fc9a1ae99a98fbb619f135001c6434849b625884a9405a60cd3d50fc3e3b07ecd38cbed7406a4fccdb59c
<dt>MONGO_URL
<dd>URL connection string for mongo in the form mongodb://username:password@example.com:port To more easily set up connections to third party mongo providers, you can call this value MONGODB_URI, MONGOLAB_URI, MONGOHQ_URL, MONGODB_URL or MONGO_URL
<dd>defaults to mongodb://localhost/errbit_&lt;Rails.env&gt;
<dt>DATABASE_AUTHENTICATION
<dd>Show the login form (username/password) on sign-in page.
<dd>defaults to true. Only hides the form, does NOT prevent any direct POST requests.
<dt>GITHUB_URL
<dd>Use this URL for interacting github. This is useful if you have a github enterprise account and you're using a URL other than https://github.com
<dd>defaults to https://github.com
<dt>GITHUB_API_URL</dt>
<dd>For github enterprise accounts, the API URL could be something like https://github.example.com/api/v3</dd>
<dd>defaults to https://api.github.com</dd>
<dt>GITHUB_AUTHENTICATION
<dd>Allow github sign-in via OAuth
<dd>defaults to true
<dt>GITHUB_CLIENT_ID
<dd>Client id of your github application
<dt>GITHUB_SECRET
<dd>Secret key for your github application
<dt>GITHUB_ORG_ID
<dd>ID of your github organization. If set, Errbit will create user accounts for users in your github organization who sign into Errbit without having a user account
<dt>GITHUB_ACCESS_SCOPE
<dd>OAuth scope to request from users when they sign-in through github
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
<dt>SAML_AUTHENTICATION
<dd>Allow SAML sign-in
<dt>SAML_SITE_TITLE
<dd>The title to use for SAML. This value is whatever you want displayed in the Errbit UI when referring to SAML.
<dt>SAML_ISSUER
<dd>Your application issuer name, could be something like 'errbit'
<dt>SAML_NAME_IDENTIFIER_FORMAT
<dd>Should be 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
<dt>SAML_IDP_SSO_TARGET_URL
<dd>URL of your identity provider
<dt>SAML_IDP_CERT
<dd>Public certificate of your identity provider as one base64 encoded string
<dt>SAML_IDP_CERT_FINGERPRINT
<dd>Fingerprint of the given IDP_CERT
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
