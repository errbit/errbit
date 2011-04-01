require 'ostruct'

if ENV['HEROKU']
  Errbit::Config = OpenStruct.new
  Errbit::Config.host = ENV['ERRBIT_HOST']
  Errbit::Config.email_from = ENV['ERRBIT_EMAIL_FROM']
  Errbit::Config.email_at_notices = [1,3,10] #ENV['ERRBIT_EMAIL_AT_NOTICES']
else
  yaml = File.read(Rails.root.join('config','config.yml'))
  config = YAML.load(yaml)

  config.merge!(config.delete(Rails.env)) if config.has_key?(Rails.env)

  Errbit::Config = OpenStruct.new(config)
end

# Set config specific values
(Errbit::Application.config.action_mailer.default_url_options ||= {}).tap do |default|
  default.merge! :host => Errbit::Config.host if default[:host].blank?
end