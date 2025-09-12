# frozen_string_literal: true

if ENV["ERRBIT_SQL_PORT"].present?
  RSpec.configure do |config|
    config.before(:suite) do
      DatabaseRewinder.clean_all
    end

    config.after(:each) do
      DatabaseRewinder.clean
    end
  end
end
