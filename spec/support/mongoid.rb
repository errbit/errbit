RSpec.configure do |config|
  config.before(:suite) do
    Mongoid::Config.truncate!

    Mongoid::Tasks::Database.create_indexes
  end

  config.before(:each) do
    Mongoid::Config.truncate!
  end
end
