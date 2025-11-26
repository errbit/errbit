# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :decorator) do |_|
    Draper::ViewContext.current.class_eval { include Haml::Helpers }
  end
end
