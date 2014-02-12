require 'ostruct'
default_config_file = Rails.root.join("config", "config.example.yml")

# Allow a Rails Engine to override config by defining it earlier
unless defined?(Errbit::Config)
  Errbit::Config = OpenStruct.new
  use_env = ENV['HEROKU'] || ENV['USE_ENV']

  # If Errbit is running on Heroku, config can be set from environment variables.
  if use_env
    Errbit::Config.host = ENV['ERRBIT_HOST']
    Errbit::Config.port = ENV['ERRBIT_PORT']
    Errbit::Config.email_from = ENV['ERRBIT_EMAIL_FROM']
    #  Not really easy to use like an env because need an array and ENV return a string :(
    # Errbit::Config.email_at_notices = ENV['ERRBIT_EMAIL_AT_NOTICES']
    Errbit::Config.confirm_err_actions = ENV['ERRBIT_CONFIRM_ERR_ACTIONS'].to_i == 0
    Errbit::Config.user_has_username = ENV['ERRBIT_USER_HAS_USERNAME'].to_i == 1
    Errbit::Config.allow_comments_with_issue_tracker = ENV['ERRBIT_ALLOW_COMMENTS_WITH_ISSUE_TRACKER'].to_i == 0
    Errbit::Config.enforce_ssl = ENV['ERRBIT_ENFORCE_SSL']

    Errbit::Config.use_gravatar = ENV['ERRBIT_USE_GRAVATAR']
    Errbit::Config.gravatar_default = ENV['ERRBIT_GRAVATAR_DEFAULT']

    Errbit::Config.github_url = ENV['GITHUB_URL']
    Errbit::Config.github_authentication = ENV['GITHUB_AUTHENTICATION']
    Errbit::Config.github_client_id = ENV['GITHUB_CLIENT_ID']
    Errbit::Config.github_secret = ENV['GITHUB_SECRET']
    Errbit::Config.github_org_id = ENV['GITHUB_ORG_ID'] if ENV['GITHUB_ORG_ID']
    Errbit::Config.github_access_scope = ENV['GITHUB_ACCESS_SCOPE'].split(',').map(&:strip) if ENV['GITHUB_ACCESS_SCOPE']

    Errbit::Config.smtp_settings = {
      :address        => ENV['SMTP_SERVER'] || 'smtp.sendgrid.net',
      :port           => ENV['SMTP_PORT']   || 25,
      :authentication => :plain,
      :user_name      => ENV['SMTP_USERNAME']   || ENV['SENDGRID_USERNAME'],
      :password       => ENV['SMTP_PASSWORD']   || ENV['SENDGRID_PASSWORD'],
      :domain         => ENV['SMTP_DOMAIN'] || ENV['SENDGRID_DOMAIN'] || ENV['ERRBIT_EMAIL_FROM'].split('@').last
    }
  end

  # Use example config for test environment.
  config_file = Rails.env == "test" ? default_config_file : Rails.root.join("config", "config.yml")

  # Load config if config file exists.
  if File.exists?(config_file)
    config = YAML.load_file(config_file)
    config.merge!(config.delete(Rails.env)) if config.has_key?(Rails.env)
    config.each do |k,v|
      Errbit::Config.send("#{k}=", v)
    end
  # Show message if we are not running tests, not running on Heroku, and config.yml doesn't exist.
  elsif not use_env
    puts "Please copy 'config/config.example.yml' to 'config/config.yml' and configure your settings. Using default settings."
  end

  # Set default devise modules
  Errbit::Config.devise_modules = [:database_authenticatable,
                                   :recoverable, :rememberable, :trackable,
                                   :validatable, :omniauthable]
end

# Set default settings from config.example.yml if key is missing from config.yml
default_config = YAML.load_file(default_config_file)
default_config.each do |k,v|
  Errbit::Config.send("#{k}=", v) if Errbit::Config.send(k) === nil
end

# Make sure the GitHub link doesn't end with a slash, so we don't have to deal
# with it later on in the code.
Errbit::Config.github_url.gsub!(/\/*\z/, '')

# Disable GitHub oauth if gem is missing
Errbit::Config.github_authentication = false unless defined?(OmniAuth::Strategies::GitHub)

# Set SMTP settings if given.
if smtp = Errbit::Config.smtp_settings
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = smtp
end

if sendmail = Errbit::Config.sendmail_settings
  ActionMailer::Base.delivery_method = :sendmail
  ActionMailer::Base.sendmail_settings = sendmail
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

if Rails.env.production?
  Rails.application.config.consider_all_requests_local = Errbit::Config.display_internal_errors
end
