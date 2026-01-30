# frozen_string_literal: true

require "configurate/provider/toml"

Config ||= Configurate::Settings.create do
  add_provider Configurate::Provider::Env
  add_provider Configurate::Provider::Dynamic if Rails.env.local?

  add_provider Configurate::Provider::TOML,
    Rails.root.join("config", "errbit.toml"), required: true
end

# ["MONGODB_URI", "MONGOLAB_URI", "MONGOHQ_URL", "MONGODB_URL", "MONGO_URL"]

if ENV.fetch("MONGODB_URI", nil).present?
  Config.errbit.mongo_url = ENV["MONGODB_URI"]
end

if ENV.fetch("MONGOLAB_URI", nil).present?
  Config.errbit.mongo_url = ENV["MONGOLAB_URI"]
end

if ENV.fetch("MONGOHQ_URL", nil).present?
  Config.errbit.mongo_url = ENV["MONGOHQ_URL"]
end

if ENV.fetch("MONGODB_URL", nil).present?
  Config.errbit.mongo_url = ENV["MONGODB_URL"]
end

if ENV.fetch("MONGO_URL", nil).present?
  # warning about deprecated ENV variable

  Config.errbit.mongo_url = ENV["MONGO_URL"]
end
