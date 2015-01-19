Mongoid.configure do |config|
  mongo_params = {
    database: Errbit::Config.mongoid_database,
    hosts: [ Errbit::Config.mongoid_host ]
  }

  if Errbit::Config.mongoid_user
    mongo_params[:username] = Errbit::Config.mongoid_user
  end

  if Errbit::Config.mongoid_password
    mongo_params[:password] = Errbit::Config.mongoid_password
  end

  config.load_configuration({
    sessions: {
      default: mongo_params
    }
  })
end

Mongoid.use_activesupport_time_zone = true
