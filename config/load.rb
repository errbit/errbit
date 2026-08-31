# frozen_string_literal: true

# load default ENV values (without overwriting any existing value)
Dotenv.load(".env.default")

require_relative "../app/lib/configurator"

# map config keys to environment variables
#
# We use the first non-nil environment variable in the list. If the last array
# element is a proc, it runs at the end, overriding the config value
Errbit::Config = Configurator.run(
  host: ["ERRBIT_HOST"],
  confirm_err_actions: {env: ["ERRBIT_CONFIRM_ERR_ACTIONS"], type: :boolean},
  user_has_username: {env: ["ERRBIT_USER_HAS_USERNAME"], type: :boolean},
  use_gravatar: {env: ["ERRBIT_USE_GRAVATAR"], type: :boolean},
  gravatar_default: ["ERRBIT_GRAVATAR_DEFAULT"],
  email_from: ["ERRBIT_EMAIL_FROM"],
  email_at_notices: {env: ["ERRBIT_EMAIL_AT_NOTICES"], type: :integer_array},
  per_app_email_at_notices: {env: ["ERRBIT_PER_APP_EMAIL_AT_NOTICES"], type: :boolean},
  notify_at_notices: {env: ["ERRBIT_NOTIFY_AT_NOTICES"], type: :integer_array},
  per_app_notify_at_notices: {env: ["ERRBIT_PER_APP_NOTIFY_AT_NOTICES"], type: :boolean},
  log_location: ["ERRBIT_LOG_LOCATION"],
  notice_deprecation_days: ["ERRBIT_PROBLEM_DESTROY_AFTER_DAYS"],

  secret_key_base: ["SECRET_KEY_BASE"],
  mongo_url: ["MONGODB_URI", "MONGOLAB_URI", "MONGOHQ_URL", "MONGODB_URL", "MONGO_URL"],

  # github
  github_url: ["GITHUB_URL", lambda do |values|
    values[:github_url].gsub(%r{/*\z}, "")
  end],
  github_authentication: {env: ["GITHUB_AUTHENTICATION"], type: :boolean},
  github_client_id: ["GITHUB_CLIENT_ID"],
  github_secret: ["GITHUB_SECRET"],
  github_org_id: {env: ["GITHUB_ORG_ID"], type: :integer},
  github_access_scope: {env: ["GITHUB_ACCESS_SCOPE"], type: :string_array},
  github_api_url: ["GITHUB_API_URL"],
  github_site_title: ["GITHUB_SITE_TITLE"],
  # google
  google_authentication: {env: ["GOOGLE_AUTHENTICATION"], type: :boolean},
  google_auto_provision: {env: ["GOOGLE_AUTO_PROVISION"], type: :boolean},
  google_site_title: ["GOOGLE_SITE_TITLE"],
  google_client_id: ["GOOGLE_CLIENT_ID"],
  google_secret: ["GOOGLE_SECRET"],
  google_redirect_uri: ["GOOGLE_REDIRECT_URI"],
  google_authorized_domains: {env: ["GOOGLE_AUTHORIZED_DOMAINS"], type: :string_array},

  email_delivery_method: ["EMAIL_DELIVERY_METHOD", lambda do |values|
    email_delivery_method = values[:email_delivery_method]

    if email_delivery_method.present?
      if email_delivery_method.is_a?(Symbol) || email_delivery_method.is_a?(String)
        email_delivery_method.to_sym
      end
    end
  end],

  # SMTP settings
  smtp_address: ["SMTP_SERVER"],
  smtp_port: {env: ["SMTP_PORT"], type: :integer},
  smtp_authentication: ["SMTP_AUTHENTICATION"],
  smtp_enable_starttls_auto: {env: ["SMTP_ENABLE_STARTTLS_AUTO"], type: :boolean},
  smtp_openssl_verify_mode: ["SMTP_OPENSSL_VERIFY_MODE"],
  smtp_user_name: ["SMTP_USERNAME", "SENDGRID_USERNAME"],
  smtp_password: ["SMTP_PASSWORD", "SENDGRID_PASSWORD"],
  smtp_domain: ["SMTP_DOMAIN", "SENDGRID_DOMAIN", lambda do |values|
    values[:smtp_domain] ||
    (values[:email_from] && values[:email_from].split("@").last) || nil
  end],

  # sendmail settings
  sendmail_location: ["SENDMAIL_LOCATION"],
  sendmail_arguments: ["SENDMAIL_ARGUMENTS"],

  devise_modules: {env: ["DEVISE_MODULES"], type: :string_array}
)
