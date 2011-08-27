require 'ostruct'

Errbit::Config = OpenStruct.new

if ENV['HEROKU']
  Errbit::Config.host = ENV['ERRBIT_HOST']
  Errbit::Config.email_from = ENV['ERRBIT_EMAIL_FROM']
  Errbit::Config.email_at_notices = [1,3,10] #ENV['ERRBIT_EMAIL_AT_NOTICES']

  Errbit::Config.report_self_errors = ENV['ERRBIT_REPORT_SELF_ERRORS']
  Errbit::Config.self_errors_host = ENV['ERRBIT_SELF_ERRORS_HOST']
  Errbit::Config.self_errors_port = ENV['ERRBIT_SELF_ERRORS_PORT']
  Errbit::Config.self_errors_api_key = ENV['ERRBIT_SELF_ERRORS_API_KEY']

  Errbit::Config.smtp_settings = {
    :address        => "smtp.sendgrid.net",
    :port           => "25",
    :authentication => :plain,
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => ENV['SENDGRID_DOMAIN']
  }
end

config_file = Rails.root.join('config', Rails.env == "test" ? "config.example.yml" : "config.yml")

if File.exists?(config_file)
  yaml = File.read(config_file)
  config = YAML.load(yaml)
  config.merge!(config.delete(Rails.env)) if config.has_key?(Rails.env)
  config.each do |k,v|
    Errbit::Config.send("#{k}=", v)
  end
end

# Set SMTP settings if given, but retain defaults if not.
if smtp = Errbit::Config.smtp_settings
  Errbit::Application.config.action_mailer.smtp_settings = smtp
end

# Set config specific values
(Errbit::Application.config.action_mailer.default_url_options ||= {}).tap do |default|
  default.merge! :host => Errbit::Config.host if default[:host].blank?
end

