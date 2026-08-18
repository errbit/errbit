# frozen_string_literal: true

RSpec.configure do |config|
  # Mongoid remains the runtime ORM while the SQL model layer is introduced.
  config.use_active_record = false if config.respond_to?(:use_active_record=)
end
