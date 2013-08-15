# Some code extract from Mongoid gem
config_file = Rails.root.join("config", "mongoid.yml")
if config_file.file? &&
  YAML.load(ERB.new(File.read(config_file)).result)[Rails.env].values.flatten.any?
  ::Mongoid.load!(config_file)
elsif ENV['HEROKU'] || ENV['USE_ENV']
  # No mongoid.yml file. Use ENV variable to define your MongoDB
  # configuration
  if mongo = ENV['MONGOLAB_URI'] || ENV['MONGOHQ_URL'] || ENV['MONGODB_URL']
    settings = URI.parse(mongo)
    database_name = settings.path.gsub(/^\//, '')
  else
    settings = OpenStruct.new({
      :host => ENV['MONGOID_HOST'],
      :port => ENV['MONGOID_PORT'],
      :user => ENV['MONGOID_USERNAME'],
      :password => ENV['MONGOID_PASSWORD']
    })
    database_name = ENV['MONGOID_DATABASE']
  end

  Mongoid.configure do |config|
    config.master = Mongo::Connection.new(
      settings.host,
      settings.port
    ).db(database_name)
    config.master.authenticate(settings.user, settings.password) if settings.user
  end
end

Mongoid.allow_dynamic_fields = false
Mongoid.use_activesupport_time_zone = true
Mongoid.identity_map_enabled = true
