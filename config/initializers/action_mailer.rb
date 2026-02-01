# frozen_string_literal: true

require_relative "configurate"

# Set SMTP settings if given.
if Config.email.delivery_method == "smtp"
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    address: Config.smtp.settings.address.to_s,
    port: Config.smtp.settings.port.to_i,
    domain: Config.smtp.settings.domain.to_s,
    user_name: Config.smtp.settings.user_name.to_s,
    password: Config.smtp.settings.password.to_s,
    authentication: Config.smtp.settings.authentication.to_sym,
    enable_starttls_auto: Config.smtp.settings.enable_starttls_auto,
    openssl_verify_mode: Config.smtp.settings.openssl_verify_mode
  }
end

if Config.email.delivery_method == "sendmail"
#   sendmail_settings = {}
#   sendmail_settings[:location] = Errbit::Config.sendmail_location if Errbit::Config.sendmail_location
#   sendmail_settings[:arguments] = Errbit::Config.sendmail_arguments if Errbit::Config.sendmail_arguments

  ActionMailer::Base.delivery_method = :sendmail
#   ActionMailer::Base.sendmail_settings = sendmail_settings
end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  options_from_config = {
    host: Config.errbit.host
  }.select { |_, v| v }

  default.reverse_merge!(options_from_config)
end
