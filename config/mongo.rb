Mongoid.configure do |config|
  if Errbit::Config.mongo_url == 'mongodb://localhost'
    uri = "mongodb://localhost/errbit_#{Rails.env}"
  else
    uri = Errbit::Config.mongo_uri
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
