# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    Mongoid::Config.truncate!

    Mongoid::Tasks::Database.create_indexes
  end

  config.before do
    Mongoid::Config.truncate!
  end
end
