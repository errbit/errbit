# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each) do
    Config.reset_dynamic!
  end

  config.after(:suite) do
    Config.reset_dynamic!
  end
end
