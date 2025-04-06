# frozen_string_literal: true

if ENV["USER_GEMFILE"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['USER_GEMFILE'] support is removed and has no effect in Errbit v0.10.0. " \
    "Remove it from configuration. " \
    "From Errbit v0.10.0+ it's always 'UserGemfile'."
  )
end

if ENV["SERVE_STATIC_ASSETS"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['SERVE_STATIC_ASSETS'] support is removed and has no effect in Errbit v0.10.0. " \
    "Remove it from configuration."
  )
end

if ENV["RACK_ENV"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['RACK_ENV'] support is removed and has no effect in Errbit v0.10.0. " \
    "Replace it with build-in Ruby on Rails ENV['RAILS_ENV']."
  )
end

if ENV["ERRBIT_ENFORCE_SSL"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['ERRBIT_ENFORCE_SSL'] support is removed and has no effect in Errbit v0.10.0. " \
    "You should run Errbit behind reverse proxy with HTTPS support. " \
    "e.g. Traefik."
  )
end

if ENV["ERRBIT_PROTOCOL"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['ERRBIT_PROTOCOL'] support is removed and has no effect in Errbit v0.10.0. " \
    "When you are running Errbit behind reverse proxy with HTTPS support, protocol is already set to https " \
    "and can't be changed."
  )
end

if ENV["ERRBIT_PORT"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['ERRBIT_PORT'] support is removed and has no effect in Errbit v0.10.0. " \
    "When you are running Errbit behind reverse proxy with HTTPS support, port is already set to 443 " \
    "and can't be changed."
  )
end

if ENV["ERRBIT_LOG_LEVEL"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['ERRBIT_LOG_LEVEL'] support is removed and has no effect in Errbit v0.10.0. " \
    "Replace it with build-in Ruby on Rails ENV['RAILS_LOG_LEVEL']."
  )
end
