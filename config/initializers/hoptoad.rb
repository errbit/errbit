if Rails.env.production? && Errbit::Config.report_self_errors.to_s != "false"
  HoptoadNotifier.configure do |config|
    config.api_key = Errbit::Config.api_key || "11e5ce322856e540481e6a0789893179"
    config.host    = Errbit::Config.host    || "errbit-central.heroku.com"
    config.port    = Errbit::Config.port    || 80
    config.secure  = config.port == 443
  end
end

