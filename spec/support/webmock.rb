# frozen_string_literal: true

require "webmock/rspec"

allowed_sites = [
  # "https://chromedriver.storage.googleapis.com",
  # "https://github.com/mozilla/geckodriver/releases",
  # "https://selenium-release.storage.googleapis.com",
  # "https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver"
]

WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_sites)
