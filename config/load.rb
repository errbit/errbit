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
  confirm_err_actions: ["ERRBIT_CONFIRM_ERR_ACTIONS"],
  user_has_username: ["ERRBIT_USER_HAS_USERNAME"],
  use_gravatar: ["ERRBIT_USE_GRAVATAR"],
  gravatar_default: ["ERRBIT_GRAVATAR_DEFAULT"],
  email_from: ["ERRBIT_EMAIL_FROM"],
  email_at_notices: ["ERRBIT_EMAIL_AT_NOTICES"],
  per_app_email_at_notices: ["ERRBIT_PER_APP_EMAIL_AT_NOTICES"],
  notify_at_notices: ["ERRBIT_NOTIFY_AT_NOTICES"],
  per_app_notify_at_notices: ["ERRBIT_PER_APP_NOTIFY_AT_NOTICES"],
  log_location: ["ERRBIT_LOG_LOCATION"],
  notice_deprecation_days: ["ERRBIT_PROBLEM_DESTROY_AFTER_DAYS"],

  secret_key_base: ["SECRET_KEY_BASE"],
  mongo_url: ["MONGODB_URI", "MONGOLAB_URI", "MONGOHQ_URL", "MONGODB_URL", "MONGO_URL"],

  # github
  github_url: ["GITHUB_URL", lambda do |values|
    values[:github_url].gsub(%r{/*\z}, "")
  end],
  github_authentication: ["GITHUB_AUTHENTICATION"],
  github_client_id: ["GITHUB_CLIENT_ID"],
  github_secret: ["GITHUB_SECRET"],
  github_org_id: ["GITHUB_ORG_ID"],
  github_access_scope: ["GITHUB_ACCESS_SCOPE"],
  github_api_url: ["GITHUB_API_URL"],
  github_site_title: ["GITHUB_SITE_TITLE"],
  # google
  google_authentication: ["GOOGLE_AUTHENTICATION"],
  google_auto_provision: ["GOOGLE_AUTO_PROVISION"],
  google_site_title: ["GOOGLE_SITE_TITLE"],
  google_client_id: ["GOOGLE_CLIENT_ID"],
  google_secret: ["GOOGLE_SECRET"],
  google_redirect_uri: ["GOOGLE_REDIRECT_URI"],
  google_authorized_domains: ["GOOGLE_AUTHORIZED_DOMAINS"],

  # OpenID Connect
  oidc_authentication: ["OIDC_AUTHENTICATION"],
  oidc_auto_provision: ["OIDC_AUTO_PROVISION"],
  oidc_site_title: ["OIDC_SITE_TITLE"],
  oidc_client_id: ["OIDC_CLIENT_ID"],
  # Read verbatim, like github_app_private_key: a client secret has no
  # business being run through YAML.
  oidc_secret: [->(_values) { ENV.fetch("OIDC_SECRET", nil) }],
  # Kept verbatim, trailing slash included: the OpenID Connect discovery
  # document is rejected unless the issuer it reports matches this string
  # exactly, and authentik reports one ending in a slash.
  oidc_issuer: ["OIDC_ISSUER"],
  oidc_scope: ["OIDC_SCOPE"],
  # Unlike the github and google strategies, omniauth_openid_connect never
  # derives the redirect URI from the request, so default it to the callback
  # route on ERRBIT_HOST. Set OIDC_REDIRECT_URI when errbit is not reached
  # over https at that host.
  oidc_redirect_uri: ["OIDC_REDIRECT_URI", lambda do |values|
    values[:oidc_redirect_uri].presence ||
      "https://#{values[:host]}/users/auth/openid_connect/callback"
  end],
  oidc_uid_field: ["OIDC_UID_FIELD"],
  oidc_authorized_domains: ["OIDC_AUTHORIZED_DOMAINS"],

  # Extra origins the sign-in flow is allowed to navigate to, for a provider
  # whose authorization endpoint does not live on the issuer's own host. See
  # config/initializers/content_security_policy.rb.
  csp_form_action_origins: ["CSP_FORM_ACTION_ORIGINS"],

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
  smtp_port: ["SMTP_PORT"],
  smtp_authentication: ["SMTP_AUTHENTICATION"],
  smtp_enable_starttls_auto: ["SMTP_ENABLE_STARTTLS_AUTO"],
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

  devise_modules: ["DEVISE_MODULES"]
)
