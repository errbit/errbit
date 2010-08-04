require 'ostruct'

yaml = File.read(Rails.root.join('config','config.yml'))
config = YAML.load(yaml)

config.merge!(config.delete(Rails.env)) if config.has_key?(Rails.env)

::App = OpenStruct.new(config)