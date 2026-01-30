# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Chrome headless
    driven_by :selenium, using: :headless_chrome
    # Chrome non-headless
    # driven_by :selenium, using: :chrome
    # Firefox headless
    # driven_by :selenium, using: :headless_firefox
    # Firefox non-headless
    # driven_by :selenium, using: :firefox
    # Rack test
    # driven_by :rack_test
  end
end
