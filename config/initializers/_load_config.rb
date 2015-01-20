# load default ENV values (without overwriting any existing value)
Dotenv.load('.env.default')

# map config keys to environment variables (with type hint)
mapping = {
  :host                => [:string,  'ERRBIT_HOST'],
  :protocol            => [:string,  'ERRBIT_PROTOCOL'],
  :port                => [:string,  'ERRBIT_PORT'],
  :enforce_ssl         => [:boolean, 'ERRBIT_ENFORCE_SSL'],
  :confirm_resolve_err => [:boolean, 'CONFIRM_RESOLVE_ERR'],
  :confirm_err_actions => [:boolean, 'ERRBIT_CONFIRM_ERR_ACTIONS'],
  :user_has_username   => [:boolean, 'ERRBIT_USER_HAS_USERNAME'],
  :use_gravatar        => [:boolean, 'ERRBIT_USE_GRAVATAR'],
  :gravatar_default    => [:string,  'ERRBIT_GRAVATAR_DEFAULT'],
  :serve_static_assets => [:boolean, 'SERVE_STATIC_ASSETS'],
  :secret_key_base     => [:string,  'SECRET_KEY_BASE'],
  :display_internal_errors => [:boolean, 'DISPLAY_INTERNAL_ERRORS'],

  :mongo_url        => [:string, 'MONGOLAB_URI', 'MONGOHQ_URL', 'MONGODB_URL', 'MONGO_URL'],
  :mongoid_host     => [:string, 'MONGOID_HOST'],
  :mongoid_port     => [:string, 'MONGOID_PORT'],
  :mongoid_username => [:string, 'MONGOID_USERNAME'],
  :mongoid_password => [:string, 'MONGOID_PASSWORD'],
  :mongoid_database => [:string, 'MONGOID_DATABASE'],

  :email_from                => [:string,  'ERRBIT_EMAIL_FROM'],
  :email_at_notices          => [:array,   'ERRBIT_EMAIL_AT_NOTICES'],
  :per_app_email_at_notices  => [:boolean, 'PER_APP_EMAIL_AT_NOTICES'],

  :notify_at_notices         => [:array,   'NOTIFY_AT_NOTICES'],
  :per_app_notify_at_notices => [:boolean, 'PER_APP_NOTIFY_AT_NOTICES'],

  # github
  :github_url            => [:string,  'GITHUB_URL'],
  :github_authentication => [:boolean, 'GITHUB_AUTHENTICATION'],
  :github_client_id      => [:string,  'GITHUB_AUTHENTICATION'],
  :github_secret         => [:string,  'GITHUB_SECRET'],
  :github_org_id         => [:string,  'GITHUB_ORG_ID'],
  :github_access_scope   => [:array,   'GITHUB_ACCESS_SCOPE'],

  :email_delivery_method => [:symbol,  'EMAIL_DELIVERY_METHOD'],

  # smtp settings
  :smtp_address          => [:string,  'SMTP_SERVER'],
  :smtp_port             => [:integer, 'SMTP_PORT'],
  :smtp_authentication   => [:symbol,  'SMTP_AUTHENTICATION'],
  :smtp_user_name        => [:string,  'SMTP_USERNAME', 'SENDGRID_USERNAME'],
  :smtp_password         => [:string,  'SMTP_PASSWORD', 'SENDGRID_PASSWORD'],
  :smtp_domain           => [:string,  'SMTP_DOMAIN', 'SENDGRID_DOMAIN'],

  # sendmail settings
  :sendmail_location     => [:string,  'SENDMAIL_LOCATION'],
  :sendmail_arguments    => [:string,  'SENDMAIL_ARGUMENTS'],

  :devise_modules        => [:array,   'DEVISE_MODULES'],
}

# any configuration that can't be simply plucked out of ENV should go here
overrides = {
  smtp_domain: ->(cache) {
    cache[:smtp_domain] ||
    (cache[:email_from] && cache[:email_from].split('@').last) ||
    nil
  },
  github_url:        ->(cache) { cache[:github_url].gsub(/\/*\z/, '') },
  devise_modules:    ->(cache) { (cache[:devise_modules] || []).map(&:to_sym) },
  email_at_notices:  ->(cache) { cache[:email_at_notices].map(&:to_i) },
  notify_at_notices: ->(cache) { cache[:notify_at_notices].map(&:to_i) },
  mongoid_settings:  ->(cache) {
    if cache[:mongo_url]
      URI.parse(cache[:mongo_url])
    else
      OpenStruct.new(
        host:     cache[:mongoid_host],
        port:     cache[:mongoid_port],
        user:     cache[:mongoid_username],
        password: cache[:mongoid_password]
      )
    end
  },
  mongoid_host: ->(cache) {
    sprintf("%s:%s", cache[:mongoid_settings].host, cache[:mongoid_settings].port)
  },
  mongoid_user: ->(cache) {
    cache[:mongoid_settings].user
  },
  mongoid_password: ->(cache) {
    cache[:mongoid_settings].password
  },
  mongoid_database: ->(cache) {
    if cache[:mongoid_settings].path
      cache[:mongoid_settings].path.gsub(/^\//, '')
    elsif cache[:mongoid_database]
      cache[:mongoid_database]
    else
      sprintf('%s_%s', 'errbit', Rails.env)
    end
  }
}

Errbit::Config = Configurator.run(mapping, overrides)

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
