require 'ostruct'
default_config_file = Rails.root.join("config", "config.example.yml")

# Allow a Rails Engine to override config by defining it earlier
unless defined?(Errbit::Config)
  Errbit::Config = OpenStruct.new

  # If Errbit is running on Heroku, config can be set from environment variables.
  if ENV['HEROKU']
    Errbit::Config.host = ENV['ERRBIT_HOST']
    Errbit::Config.email_from = ENV['ERRBIT_EMAIL_FROM']
    Errbit::Config.email_at_notices = ENV['ERRBIT_EMAIL_AT_NOTICES']
    Errbit::Config.confirm_resolve_err = ENV['ERRBIT_CONFIRM_RESOLVE_ERR']
    Errbit::Config.user_has_username = ENV['ERRBIT_USER_HAS_USERNAME']
    Errbit::Config.allow_comments_with_issue_tracker = ENV['ERRBIT_ALLOW_COMMENTS_WITH_ISSUE_TRACKER']
    Errbit::Config.enforce_ssl = ENV['ERRBIT_ENFORCE_SSL']

    Errbit::Config.use_gravatar = ENV['ERRBIT_USE_GRAVATAR']
    Errbit::Config.gravatar_default = ENV['ERRBIT_GRAVATAR_DEFAULT']

    Errbit::Config.github_authentication = ENV['GITHUB_AUTHENTICATION']
    Errbit::Config.github_client_id = ENV['GITHUB_CLIENT_ID']
    Errbit::Config.github_secret = ENV['GITHUB_SECRET']
    Errbit::Config.github_access_scope = ENV['GITHUB_ACCESS_SCOPE'].split(',').map(&:strip) if ENV['GITHUB_ACCESS_SCOPE']

    Errbit::Config.smtp_settings = {
      :address        => "smtp.sendgrid.net",
      :port           => "25",
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => ENV['SENDGRID_DOMAIN']
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
  elsif not ENV['HEROKU']
    puts "Please copy 'config/config.example.yml' to 'config/config.yml' and configure your settings. Using default settings."
  end

  # Set default devise modules
  Errbit::Config.devise_modules = [:database_authenticatable,
                                   :recoverable, :rememberable, :trackable,
                                   :validatable, :token_authenticatable, :omniauthable]
end

# Set default settings from config.example.yml if key is missing from config.yml
default_config = YAML.load_file(default_config_file)
default_config.each do |k,v|
  Errbit::Config.send("#{k}=", v) if Errbit::Config.send(k) === nil
end

# Set SMTP settings if given.
if smtp = Errbit::Config.smtp_settings
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = smtp
end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  default.merge! :host => Errbit::Config.host if default[:host].blank?
end

