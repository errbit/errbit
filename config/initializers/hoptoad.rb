HoptoadNotifier.configure do |config|
  # Internal Errbit errors are stored locally, but we need
  # to set a dummy API key so that HoptoadNotifier doesn't complain.
  config.api_key = "---------"

  # Don't log error that causes 404 page
  config.ignore << "Mongoid::Errors::DocumentNotFound"
end

