# load default ENV values (without overwriting any existing value)
Dotenv.load('.env.default')

# map config keys to environment variables
#
# We use the first non-nil environment variable in the list. If the last array
# element is a proc, it runs at the end, overriding the config value
Errbit::Config = Configurator.run({
  host:                      ['ERRBIT_HOST'],
  protocol:                  ['ERRBIT_PROTOCOL'],
  port:                      ['ERRBIT_PORT'],
  enforce_ssl:               ['ERRBIT_ENFORCE_SSL'],
  confirm_err_actions:       ['ERRBIT_CONFIRM_ERR_ACTIONS'],
  user_has_username:         ['ERRBIT_USER_HAS_USERNAME'],
  use_gravatar:              ['ERRBIT_USE_GRAVATAR'],
  gravatar_default:          ['ERRBIT_GRAVATAR_DEFAULT'],
  serve_static_assets:       ['SERVE_STATIC_ASSETS'],
  secret_key_base:           ['SECRET_KEY_BASE'],
  display_internal_errors:   ['DISPLAY_INTERNAL_ERRORS'],
  mongo_url:                 ['MONGOLAB_URI', 'MONGOHQ_URL', 'MONGODB_URL', 'MONGO_URL'],

  email_from:                ['ERRBIT_EMAIL_FROM'],
  email_at_notices:          ['ERRBIT_EMAIL_AT_NOTICES'],
  per_app_email_at_notices:  ['PER_APP_EMAIL_AT_NOTICES'],

  notify_at_notices:         ['NOTIFY_AT_NOTICES'],
  per_app_notify_at_notices: ['PER_APP_NOTIFY_AT_NOTICES'],

  # github
  github_url:                ['GITHUB_URL', ->(values) {
    values[:github_url].gsub(/\/*\z/, '')
  }],
  github_authentication:     ['GITHUB_AUTHENTICATION'],
  github_client_id:          ['GITHUB_AUTHENTICATION'],
  github_secret:             ['GITHUB_SECRET'],
  github_org_id:             ['GITHUB_ORG_ID'],
  github_access_scope:       ['GITHUB_ACCESS_SCOPE'],

  email_delivery_method:     ['EMAIL_DELIVERY_METHOD'],

  # smtp settings
  smtp_address:              ['SMTP_SERVER'],
  smtp_port:                 ['SMTP_PORT'],
  smtp_authentication:       ['SMTP_AUTHENTICATION'],
  smtp_user_name:            ['SMTP_USERNAME', 'SENDGRID_USERNAME'],
  smtp_password:             ['SMTP_PASSWORD', 'SENDGRID_PASSWORD'],
  smtp_domain:               ['SMTP_DOMAIN', 'SENDGRID_DOMAIN', ->(values) {
    values[:smtp_domain] ||
    (values[:email_from] && values[:email_from].split('@').last)||
    nil
  }],

  # sendmail settings
  sendmail_location:         ['SENDMAIL_LOCATION'],
  sendmail_arguments:        ['SENDMAIL_ARGUMENTS'],

  devise_modules:            ['DEVISE_MODULES'],
})

# Set SMTP settings if given.
if Errbit::Config.email_delivery_method == :smtp
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address        => Errbit::Config.smtp_address,
    :port           => Errbit::Config.smtp_port,
    :authentication => Errbit::Config.smtp_authentication,
    :user_name      => Errbit::Config.smtp_user_name,
    :password       => Errbit::Config.smtp_password,
    :domain         => Errbit::Config.smtp_domain,
  }
end

if Errbit::Config.email_delivery_method == :sendmail
  ActionMailer::Base.delivery_method = :sendmail

  sendmail_settings = {}
  sendmail_settings[:location] = Errbit::Config.sendmail_location if Errbit::Config.sendmail_location
  sendmail_settings[:arguments] = Errbit::Config.sendmail_arguments if Errbit::Config.sendmail_arguments

  ActionMailer::Base.sendmail_settings = sendmail_settings
end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  options_from_config = {
    host: Errbit::Config.host,
    port: Errbit::Config.port,
    protocol: Errbit::Config.protocol
  }.select { |k, v| v }

  default.reverse_merge!(options_from_config)
end

Rails.application.config.consider_all_requests_local = Errbit::Config.display_internal_errors
Rails.application.config.serve_static_assets = Errbit::Config.serve_static_assets
Rails.application.config.secret_key_base = Errbit::Config.secret_key_base
