require 'capybara/rspec'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist

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

def mock_gds_sso_auth(uid, details = {})
  OmniAuth.config.mock_auth[:gds] = gds_omniauth_hash_stub(uid, details)
end

def clear_gds_sso_auth_mock!
  OmniAuth.config.mock_auth[:gds] = nil
end

def log_in(user)
  user.update_attributes!(:uid => Devise.friendly_token) if user.uid.blank?
  mock_gds_sso_auth(user.uid,
                   :email => user.email,
                   :name => user.name,
                   :permissions => user.admin? ? %w(signin admin) : %w(signin)
                   )
  visit '/'
end
