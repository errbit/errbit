require 'ostruct'

config_file = Rails.root.join('config', Rails.env == "test" ? "config.example.yml" : "config.yml")
Errbit::Config = nil # assign global scope
if File.exists?(config_file)
  yaml = File.read(config_file)
  config = YAML.load(yaml)

  config.merge!(config.delete(Rails.env)) if config.has_key?(Rails.env)

  Errbit::Config = OpenStruct.new(config)
elsif ENV['HEROKU']
  Errbit::Config = OpenStruct.new
  Errbit::Config.host = ENV['ERRBIT_HOST']
  Errbit::Config.email_from = ENV['ERRBIT_EMAIL_FROM']
  Errbit::Config.email_at_notices = [1,3,10] #ENV['ERRBIT_EMAIL_AT_NOTICES']
  Errbit::Application.config.action_mailer.smtp_settings = {
    :address        => "smtp.sendgrid.net",
    :port           => "25",
    :authentication => :plain,
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => ENV['SENDGRID_DOMAIN']
  }
else
  raise("Missing config file #{config_file}")
end

# Set config specific values
(Errbit::Application.config.action_mailer.default_url_options ||= {}).tap do |default|
  default.merge! :host => Errbit::Config.host if default[:host].blank?
end

