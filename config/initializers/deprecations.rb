if ENV["USER_GEMFILE"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  ActiveSupport::Deprecation.warn(
    "ENV['USER_GEMFILE'] support is and has no effect in Errbit v0.10.0. " \
    "Remove it from configuration. " \
    "From Errbit v0.10.0+ it's always 'UserGemfile'."
  )
end
