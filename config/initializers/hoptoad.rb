HoptoadNotifier.configure do |config|
  # Internal Errbit errors are stored locally, but we need
  # to set a dummy API key so that HoptoadNotifier doesn't complain.
  config.api_key = "---------"
end

