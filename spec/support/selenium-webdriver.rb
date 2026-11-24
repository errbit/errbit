# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, type: :system) do |example|
    original_full_host = OmniAuth.config.full_host
    begin
      example.run
    ensure
      OmniAuth.config.full_host = original_full_host
    end
  end

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

    OmniAuth.config.full_host = Capybara.current_session.server.base_url
  end
end
