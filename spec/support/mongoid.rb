# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    next if ENV["SKIP_MONGOID"] == "true"

    Mongoid::Config.truncate!

    Mongoid::Tasks::Database.create_indexes
  end

  config.before do
    next if ENV["SKIP_MONGOID"] == "true"

    Mongoid::Config.truncate!
  end
end
