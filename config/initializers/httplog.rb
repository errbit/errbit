if defined?(HttpLog)
  HttpLog.configure do |config|
    # Enable or disable all logging
    config.enabled = true
  end
end
