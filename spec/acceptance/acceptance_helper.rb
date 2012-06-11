require 'spec_helper'
require 'capybara/rspec'

OmniAuth.config.test_mode = true

def mock_auth(user = "test_user", token = "abcdef")
  OmniAuth.config.mock_auth[:github] = Hashie::Mash.new(
    'provider' => 'github',
    'uid' => '1763',
    'extra' => {
      'raw_info' => {
        'login' => user
      }
    },
    'credentials' => {
      'token' => token
    }
  )
end
