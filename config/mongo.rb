# frozen_string_literal: true

# log_level = "info"
#
# logger = Logger.const_get log_level.upcase
#
# Mongoid.logger.level = logger
# Mongo::Logger.level = logger

mongo_url = "mongodb://localhost"

# mongo_url = case
#             when
#
#             else Config.errbit.mongo_url
#             end

Mongoid.configure do |config|
  uri = if mongo_url == "mongodb://localhost"
    "mongodb://localhost/errbit_#{Rails.env}"
  else
    mongo_url
  end

  config.load_configuration(
    clients: {
      default: {
        uri: uri
      }
    }
  )
end
