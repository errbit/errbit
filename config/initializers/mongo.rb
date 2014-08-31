# Some code extract from Mongoid gem
config_file = Rails.root.join("config", "mongoid.yml")
if config_file.file? &&
  YAML.load(ERB.new(File.read(config_file)).result)[Rails.env].values.flatten.any?
  ::Mongoid.load!(config_file)
elsif ENV['HEROKU'] || ENV['USE_ENV']
  # No mongoid.yml file. Use ENV variable to define your MongoDB
  # configuration
  if mongo = ENV['MONGOLAB_URI'] || ENV['MONGOHQ_URL'] || ENV['MONGODB_URL'] || ENV['MONGO_URL']
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

    hash = {
      sessions: {
        default: {
          database: database_name,
          hosts: [ "#{settings.host}:#{settings.port}" ]
        }
      },
    }

    if settings.user && settings.password
      hash[:sessions][:default][:username] = settings.user
      hash[:sessions][:default][:password] = settings.password
    end

    config.load_configuration(hash)
  end
end

Mongoid.allow_dynamic_fields = false
Mongoid.use_activesupport_time_zone = true
Mongoid.identity_map_enabled = true
