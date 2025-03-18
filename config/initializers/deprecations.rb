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
    "Replace it with build-in Ruby on Rails ENV['RAILS_SERVE_STATIC_FILES']."
  )
end

if ENV["RACK_ENV"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['RACK_ENV'] support is removed and has no effect in Errbit v0.10.0. " \
    "Replace it with build-in Ruby on Rails ENV['RAILS_ENV']."
  )
end
