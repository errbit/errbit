require 'capybara/rspec'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist

OmniAuth.config.test_mode = true

def mock_auth(user = "test_user", token = "abcdef")
  OmniAuth.config.mock_auth[:github] = Hashie::Mash.new(
    'provider'    => 'github',
    'uid'         => '1763',
    'extra'       => {
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

  if Errbit::Config.user_has_username
    fill_in :user_username, with: user.username
  else
    fill_in :user_email, with: user.email
  end

  fill_in :user_password, with: 'password'
  click_on I18n.t('devise.sessions.new.sign_in')
end
