# frozen_string_literal: true

# Set SMTP settings if given.
if Rails.configuration.errbit.email_delivery_method == "smtp"
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    address: Rails.configuration.errbit.smtp_address,
    port: Rails.configuration.errbit.smtp_port,
    domain: Rails.configuration.errbit.smtp_domain,
    user_name: Rails.configuration.errbit.smtp_user_name,
    password: Rails.configuration.errbit.smtp_password,
    authentication: Rails.configuration.errbit.smtp_authentication,
    enable_starttls_auto: Rails.configuration.errbit.smtp_enable_starttls_auto,
    openssl_verify_mode: Rails.configuration.errbit.smtp_openssl_verify_mode
  }
end

if Rails.configuration.errbit.email_delivery_method == "sendmail"
  ActionMailer::Base.delivery_method = :sendmail

  sendmail_settings = {}

  if Rails.configuration.errbit.sendmail_location.present?
    sendmail_settings[:location] = Rails.configuration.errbit.sendmail_location
  end

  if Rails.configuration.errbit.sendmail_arguments.present?
    sendmail_settings[:arguments] = Rails.configuration.errbit.sendmail_arguments
  end

  ActionMailer::Base.sendmail_settings = sendmail_settings
end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  options_from_config = {
    host: Rails.configuration.errbit.host
  }.select { |_, v| v }

  default.reverse_merge!(options_from_config)
end
