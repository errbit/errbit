# frozen_string_literal: true

# log_level = "info"
#
# logger = Logger.const_get log_level.upcase
#
# Mongoid.logger.level = logger
# Mongo::Logger.level = logger

Mongoid.configure do |config|
  uri = if Config.errbit.mongo_url == "mongodb://localhost"
    "mongodb://localhost/errbit_#{Rails.env}"
  else
    Config.errbit.mongo_url
  end

  config.load_configuration(
    clients: {
      default: {
        uri: uri
      }
    }
  )
end
