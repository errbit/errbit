# frozen_string_literal: true

RSpec.configure do |config|
  config.include Mongoid::Matchers, type: :model
end
