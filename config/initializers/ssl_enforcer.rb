# Enforce SSL connections, if configured
if Errbit::Config.enforce_ssl
  require 'rack/ssl-enforcer'
  ActionMailer::Base.default_url_options.merge!(:protocol => 'https://')
  Rails.application.configure do
    config.middleware.use Rack::SslEnforcer, :except => /^\/deploys/
  end
end
