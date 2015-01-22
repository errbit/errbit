Mongoid.configure do |config|
  mongo_params = {
    database: Errbit::Config.mongoid_database,
    hosts: [
      sprintf(
        "%s:%s",
        Errbit::Config.mongoid_settings.host,
        Errbit::Config.mongoid_settings.port
      )
    ]
  }

  if Errbit::Config.mongoid_settings.user
    mongo_params[:username] = Errbit::Config.mongoid_settings.user
  end

  if Errbit::Config.mongoid_settings.password
    mongo_params[:password] = Errbit::Config.mongoid_settings.password
  end

  config.load_configuration({
    sessions: {
      default: mongo_params
    }
  })
end

Mongoid.use_activesupport_time_zone = true
