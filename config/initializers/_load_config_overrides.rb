# Load any config overrides from the overrides file.
#
# These will overwrite any settings set elsewhere.

unless Rails.env.test?
  errbit_uri = URI.parse(Plek.new.find('errbit'))
  Errbit::Config.host = errbit_uri.host
  Errbit::Config.protocol = errbit_uri.scheme
end

overrides_config_file = Rails.root.join("config", "config_overrides.yml")

config = YAML.load_file(overrides_config_file)
config.each do |k,v|
  Errbit::Config.send("#{k}=", v)
end
