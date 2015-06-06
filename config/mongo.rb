Mongoid.logger.level = Logger.const_get Errbit::Config.log_level.upcase

Mongoid.configure do |config|
  uri = if Errbit::Config.mongo_url == 'mongodb://localhost'
          "mongodb://localhost/errbit_#{Rails.env}"
        else
          Errbit::Config.mongo_url
        end

  config.load_configuration({
    sessions: {
      default: {
        uri: uri
      }
    },
    options: {
      use_activesupport_time_zone: true
    }
  })
end
