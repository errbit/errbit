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

def log_in(user)
  visit '/'
  fill_in :user_email, :with => user.email
  fill_in :user_password, :with => 'password'
  click_on I18n.t('devise.sessions.new.sign_in')
end
