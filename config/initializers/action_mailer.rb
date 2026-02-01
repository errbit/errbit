# frozen_string_literal: true

# Set SMTP settings if given.
# if Config.email.delivery_method == "smtp"
#   ActionMailer::Base.delivery_method = :smtp
#   ActionMailer::Base.smtp_settings = {
#     address: Config.smtp.settings.address.get,
#     port: Config.smtp.settings.port.to_i,
#     domain: Config.smtp.settings.domain.get,
#     user_name: Config.smtp.settings.user_name.get,
#     password: Config.smtp.settings.password.get,
#     authentication: Config.smtp.settings.authentication.get&.to_sym,
#     enable_starttls_auto: Config.smtp.settings.enable_starttls_auto?,
#     openssl_verify_mode: Config.smtp.settings.openssl_verify_mode.get
#   }
# end

# if Config.email.delivery_method == "sendmail"
#   sendmail_settings = {}
#   sendmail_settings[:location] = Config.sendmail.settings.location if Config.sendmail.settings.location.present?
#   sendmail_settings[:arguments] = Config.sendmail.settings.arguments if Config.sendmail.settings.arguments.present?
#
#   ActionMailer::Base.delivery_method = :sendmail
#   ActionMailer::Base.sendmail_settings = sendmail_settings
# end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  options_from_config = {
    host: Rails.configuration.errbit.host
  }.select { |_, v| v }

  default.reverse_merge!(options_from_config)
end
