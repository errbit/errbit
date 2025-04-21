# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Chrome headless
    driven_by :selenium_chrome_headless
    # Chrome non-headless
    # driven_by :selenium_chrome
    # Firefox headless
    # driven_by :selenium_headless
    # Firefox non-headless
    # driven_by :selenium
    # Rack test
    # driven_by :rack_test
  end
end
