# frozen_string_literal: true

log_level = Logger.const_get Errbit::Config.log_level.upcase

Mongoid.logger.level = log_level
Mongo::Logger.level = log_level

Mongoid.configure do |config|
  uri = if Errbit::Config.mongo_url == "mongodb://localhost"
    "mongodb://localhost/errbit_#{Rails.env}"
  else
    Errbit::Config.mongo_url
  end

  config.load_configuration(
    clients: {
      default: {
        uri: uri
      }
    }
  )
end
