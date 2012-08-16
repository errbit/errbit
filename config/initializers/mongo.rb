if mongo = ENV['MONGOLAB_URI'] || ENV['MONGOHQ_URL']
  settings = URI.parse(mongo)
  database_name = settings.path.gsub(/^\//, '')

  Mongoid.configure do |config|
    config.master = Mongo::Connection.new(settings.host, settings.port).db(database_name)
    config.master.authenticate(settings.user, settings.password) if settings.user
    config.allow_dynamic_fields = false
    config.use_activesupport_time_zone = true
  end
end

