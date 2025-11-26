# frozen_string_literal: true

RSpec.configure do |config|
  config.include Haml, type: :helper
  config.include Haml::Helpers, type: :helper
end
