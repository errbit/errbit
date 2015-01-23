require 'uri'

Mongoid.configure do |config|
  uri = URI.parse(Errbit::Config.mongo_url)
  uri.path = "/errbit_#{Rails.env}" if uri.path.empty?

  config.load_configuration({
    sessions: {
      default: {
        uri: uri.to_s
      }
    },
    options: {
      use_activesupport_time_zone: true
    }
  })
end
