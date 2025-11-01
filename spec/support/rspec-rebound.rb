# frozen_string_literal: true

require "rspec/rebound"

RSpec.configure do |config|
  # show retry status in spec process
  config.verbose_retry = true

  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # run retry only on features
  # config.around :each, :js do |ex|
  #   ex.run_with_retry retry: 3
  # end

  # callback to be run when a flaky test is detected
  # config.flaky_test_callback = proc do |example|
  #   Rspec::Watchdog::Reporter.report(example)
  # end

  # callback to be run between retries
  # config.retry_callback = proc do |ex|
  #   # run some additional clean up task - can be filtered by example metadata
  #   if ex.metadata[:js]
  #     Capybara.reset!
  #   end
  # end
end
