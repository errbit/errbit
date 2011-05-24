HoptoadNotifier.configure do |config|
  config.api_key = Errbit::Config.api_key
  config.host    = Errbit::Config.host
  config.port    = Errbit::Config.port
  config.secure  = Errbit::Config.secure
end if Rails.env.production? && Errbit::Config.api_key

