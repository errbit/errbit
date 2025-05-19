# frozen_string_literal: true

require "rspec/retry"

RSpec.configure do |config|
  # show retry status in spec process
  config.verbose_retry = true

  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # run retry only on system tests
  config.around :each, :system do |ex|
    ex.run_with_retry retry: 3
  end

  # callback to be run between retries
  config.retry_callback = proc do |ex|
    # run some additional clean up task - can be filtered by example metadata
    # Reset the session (i.e. remove cookies and navigate to blank page).
    if ex.metadata[:system]
      Capybara.reset_session!
    end
  end
end
