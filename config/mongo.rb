# frozen_string_literal: true

# log_level = "info"
#
# logger = Logger.const_get log_level.upcase
#
# Mongoid.logger.level = logger
# Mongo::Logger.level = logger

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
