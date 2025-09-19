# frozen_string_literal: true

if ENV["ERRBIT_SQL_PORT"].present?
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec

      with.library :rails
    end
  end
end
