# frozen_string_literal: true

require "rspec/retry"

RSpec.configure do |config|
  # show retry status in spec process
  config.verbose_retry = true

  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # callback to be run between retries
  config.retry_callback = proc do |ex|
    # run some additional clean up task - can be filtered by example metadata
    # Reset sessions, cleaning out the pool of sessions. This will remove any
    # session information such as cookies.
    if ex.metadata[:system]
      Capybara.reset_session!
    end
  end
end
