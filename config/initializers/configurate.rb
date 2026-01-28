# frozen_string_literal: true

require "configurate/provider/toml"

Config = Configurate::Settings.create do
  add_provider Configurate::Provider::TOML,
    Rails.root.join("config", "errbit.toml"), required: false
end
