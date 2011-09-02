HoptoadNotifier.configure do |config|
  config.api_key = Errbit::Config.self_errors_api_key || "11e5ce322856e540481e6a0789893179"
  config.host    = Errbit::Config.self_errors_host    || "errbit-central.heroku.com"
  config.port    = Errbit::Config.self_errors_port    || 80
  config.secure  = config.port == 443
end

