# frozen_string_literal: true

# log_level = "info"
#
# logger = Logger.const_get log_level.upcase
#
# Mongoid.logger.level = logger
# Mongo::Logger.level = logger

Mongoid.configure do |config|
  uri = Errbit::Config.mongo_url.presence || "mongodb://localhost/errbit_#{Rails.env}"

  config.load_configuration(
    clients: {
      default: {
        uri: uri
      }
    }
  )
end
