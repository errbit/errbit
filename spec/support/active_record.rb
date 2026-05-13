# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseRewinder.clean_all
  end

  config.after do
    DatabaseRewinder.clean
  end
end
