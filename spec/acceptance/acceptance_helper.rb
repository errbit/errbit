require 'spec_helper'
require 'capybara/rspec'

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.before(:each) do
    OmniAuth.config.mock_auth[:github] = Hashie::Mash.new(
      'provider' => 'github',
      'uid' => '1763',
      'extra' => {
        'raw_info' => {
          'login' => 'nashby'
        }
      }
    )
  end
end
