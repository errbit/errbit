# load default ENV values (without overwriting any existing value)
Dotenv.load('.env.default')

require_relative '../lib/configurator'

# map config keys to environment variables
#
# We use the first non-nil environment variable in the list. If the last array
# element is a proc, it runs at the end, overriding the config value
Errbit::Config = Configurator.run(
  host:                      ['ERRBIT_HOST'],
  protocol:                  ['ERRBIT_PROTOCOL'],
  port:                      ['ERRBIT_PORT'],
  enforce_ssl:               ['ERRBIT_ENFORCE_SSL'],
  confirm_err_actions:       ['ERRBIT_CONFIRM_ERR_ACTIONS'],
  user_has_username:         ['ERRBIT_USER_HAS_USERNAME'],
  use_gravatar:              ['ERRBIT_USE_GRAVATAR'],
  gravatar_default:          ['ERRBIT_GRAVATAR_DEFAULT'],
  email_from:                ['ERRBIT_EMAIL_FROM'],
  email_at_notices:          ['ERRBIT_EMAIL_AT_NOTICES'],
  per_app_email_at_notices:  ['ERRBIT_PER_APP_EMAIL_AT_NOTICES'],
  notify_at_notices:         ['ERRBIT_NOTIFY_AT_NOTICES'],
  per_app_notify_at_notices: ['ERRBIT_PER_APP_NOTIFY_AT_NOTICES'],
  log_location:              ['ERRBIT_LOG_LOCATION'],
  log_level:                 ['ERRBIT_LOG_LEVEL'],

  serve_static_assets:       ['SERVE_STATIC_ASSETS'],
  secret_key_base:           ['SECRET_KEY_BASE'],
  mongo_url:                 %w(MONGOLAB_URI MONGOHQ_URL MONGODB_URL MONGO_URL),

  # github
  github_url:                ['GITHUB_URL', lambda do |values|
    values[:github_url].gsub(%r{/*\z}, '')
  end],
  github_authentication:     ['GITHUB_AUTHENTICATION'],
  github_client_id:          ['GITHUB_CLIENT_ID'],
  github_secret:             ['GITHUB_SECRET'],
  github_org_id:             ['GITHUB_ORG_ID'],
  github_access_scope:       ['GITHUB_ACCESS_SCOPE'],
  github_api_url:            ['GITHUB_API_URL'],
  github_site_title:         ['GITHUB_SITE_TITLE'],

  email_delivery_method:     ['EMAIL_DELIVERY_METHOD', lambda do |values|
    values[:email_delivery_method] && values[:email_delivery_method].to_sym
  end],

  # smtp settings
  smtp_address:              ['SMTP_SERVER'],
  smtp_port:                 ['SMTP_PORT'],
  smtp_authentication:       ['SMTP_AUTHENTICATION'],
  smtp_user_name:            %w(SMTP_USERNAME SENDGRID_USERNAME),
  smtp_password:             %w(SMTP_PASSWORD SENDGRID_PASSWORD),
  smtp_domain:               ['SMTP_DOMAIN', 'SENDGRID_DOMAIN', lambda do |values|
    values[:smtp_domain] ||
    (values[:email_from] && values[:email_from].split('@').last) || nil
  end],

  # sendmail settings
  sendmail_location:         ['SENDMAIL_LOCATION'],
  sendmail_arguments:        ['SENDMAIL_ARGUMENTS'],

  devise_modules:            ['DEVISE_MODULES']
)
