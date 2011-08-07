if mongo = ENV['MONGOHQ_URL'] || ENV['MONGOLAB_URI']
  settings = URI.parse(mongo)
  database_name = settings.path.gsub(/^\//, '')

  Mongoid.configure do |config|
    config.master = Mongo::Connection.new(settings.host, settings.port).db(database_name)
    config.master.authenticate(settings.user, settings.password) if settings.user
    config.allow_dynamic_fields = false
  end
end
