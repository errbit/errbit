# frozen_string_literal: true

# Enforce SSL connections, if configured
if Errbit::Config.enforce_ssl
  require "rack/ssl-enforcer"
  ActionMailer::Base.default_url_options[:protocol] = "https://"
  Rails.application.configure do
    config.middleware.use Rack::SslEnforcer
  end
end
