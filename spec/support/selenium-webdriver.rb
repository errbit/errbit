# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end

  config.before(:each, type: :feature) do
    driver = ENV["HEADLESS"] == "false" ? :selenium_chrome : :selenium_chrome_headless
    Capybara.current_driver = driver
  end

  config.after(:each, type: :feature) do
    Capybara.use_default_driver
  end
end
