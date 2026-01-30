# frozen_string_literal: true

deprecator = ActiveSupport::Deprecation.new(nil, "Errbit")

class Errbit::DeprecationError < RuntimeError; end

if ENV["USER_GEMFILE"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['USER_GEMFILE'] support was removed in Errbit v0.10.0."
end

if ENV["SERVE_STATIC_ASSETS"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['SERVE_STATIC_ASSETS'] support was removed in Errbit v0.10.0."
end

if ENV["RACK_ENV"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['RACK_ENV'] support was removed in Errbit v0.10.0."
end

if ENV["ERRBIT_ENFORCE_SSL"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['ERRBIT_ENFORCE_SSL'] support was removed in Errbit v0.10.0."
end

if ENV["ERRBIT_PROTOCOL"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['ERRBIT_PROTOCOL'] support was removed in Errbit v0.10.0."
end

if ENV["ERRBIT_PORT"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['ERRBIT_PORT'] support was removed in Errbit v0.10.0."
end

if ENV["ERRBIT_LOG_LEVEL"].present?
  # Make it error in v0.11.0 release and remove in v0.12.0
  raise Errbit::DeprecationError, "ENV['ERRBIT_PORT'] support was removed in Errbit v0.10.0."
end
