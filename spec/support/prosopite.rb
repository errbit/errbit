# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Prosopite.scan
  end

  config.after do
    Prosopite.finish
  end
end
