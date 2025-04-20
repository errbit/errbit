# frozen_string_literal: true

# https://github.com/teamcapybara/capybara/blob/3.40.0/lib/capybara/registrations/drivers.rb#L31-L41
Capybara.register_driver :selenium_chrome_headless do |app|
  version = Capybara::Selenium::Driver.load_selenium

  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options

  browser_options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument("--headless=new")
    opts.add_argument("--disable-gpu") if Gem.win_platform?
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument("--disable-site-isolation-trials")

    # https://stackoverflow.com/questions/78758185/is-there-any-way-to-handle-change-your-password-prompt-in-google-chrome-using-se
    opts.add_preference("profile.password_manager_leak_detection", false)
  end

  Capybara::Selenium::Driver.new(app, **{ :browser => :chrome, options_key => browser_options })
end

Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, browser: :firefox)
end

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--headless")

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end
