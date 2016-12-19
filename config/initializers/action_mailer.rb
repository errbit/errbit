# Set SMTP settings if given.
if Errbit::Config.email_delivery_method == :smtp
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    address:              Errbit::Config.smtp_address,
    port:                 Errbit::Config.smtp_port,
    authentication:       Errbit::Config.smtp_authentication,
    user_name:            Errbit::Config.smtp_user_name,
    password:             Errbit::Config.smtp_password,
    domain:               Errbit::Config.smtp_domain,
    enable_starttls_auto: Errbit::Config.smtp_enable_starttls_auto,
    openssl_verify_mode:  Errbit::Config.smtp_openssl_verify_mode
  }
end

if Errbit::Config.email_delivery_method == :sendmail
  sendmail_settings = {}
  sendmail_settings[:location] = Errbit::Config.sendmail_location if Errbit::Config.sendmail_location
  sendmail_settings[:arguments] = Errbit::Config.sendmail_arguments if Errbit::Config.sendmail_arguments

  ActionMailer::Base.delivery_method = :sendmail
  ActionMailer::Base.sendmail_settings = sendmail_settings
end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  options_from_config = {
    host:     Errbit::Config.host,
    port:     Errbit::Config.port,
    protocol: Errbit::Config.protocol
  }.select { |_k, v| v }

  default.reverse_merge!(options_from_config)
end
