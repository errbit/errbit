require 'acceptance/acceptance_helper'

feature 'Sign in with GDS SSO' do

  def mock_gds_sso_auth(uid, details = {})
    OmniAuth.config.mock_auth[:gds] = gds_omniauth_hash_stub(uid, details)
  end

  context "no existing local user" do
    scenario 'logging in as a user with signin permission' do
      mock_gds_sso_auth('1234')
      visit '/users/auth/gds'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      u = User.where(:uid => '1234').first
      expect(u).to be
      expect(u.name).to eq("Test User")
      expect(u.email).to eq("test@example.com")
      expect(u.admin).to be_false
    end

    scenario 'logging in as a signon with admin permission sets local admin flag' do
      mock_gds_sso_auth('1234', :permissions => %w(signin admin))
      visit '/users/auth/gds'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      u = User.where(:uid => '1234').first
      expect(u).to be
      expect(u.admin).to be_true
    end

    scenario 'attempting to log in as a user without signin permission' do
      mock_gds_sso_auth('1234', :permissions => [])
      visit '/users/auth/gds'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.failure", :kind => 'GDS Signon', :reason => "Computer says no"))

      u = User.where(:uid => '1234').first
      expect(u).to be_nil
    end
  end
end
