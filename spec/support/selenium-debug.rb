# frozen_string_literal: true

# https://bibwild.wordpress.com/2024/10/08/getting-rspec-capybara-browser-console-output-for-failed-tests/
# RSpec.configure do |config|
#   # hacky way to inject browser logs into failure message for failed ones
#   config.after(:each) do
#     if example.exception
#       browser_logs = page.driver.browser.logs.get(:browser).collect { |log| "#{log.level}: #{log.message}" }
#
#       if browser_logs.present?
#         # pretty hacky internal way to get browser logs into
#         # existing long-form failure message, when that is
#         # stored in exception associated with assertion failure
#         new_exception = example.exception.class.new("#{example.exception.message}\n\nBrowser console:\n\n#{browser_logs.join("\n")}\n")
#         new_exception.set_backtrace(example.exception.backtrace)
#
#         example.display_exception = new_exception
#       end
#     end
#   end
# end

Capybara.javascript_driver = :my_headless_chrome

Capybara.register_driver :my_headless_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << '--headless'
    opts.args << '--disable-gpu'
    opts.args << '--no-sandbox'
    opts.args << '--window-size=1280,1696'

    opts.add_option('goog:loggingPrefs', browser: 'ALL')
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end
