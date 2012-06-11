#
# Enforce SSL connections, if configured
if Errbit::Config.enforce_ssl
  Errbit::Application.configure do
    config.middleware.use Rack::SslEnforcer, :except => /^\/deploys/
  end
end
