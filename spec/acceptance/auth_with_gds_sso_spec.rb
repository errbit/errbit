require 'acceptance/acceptance_helper'

feature 'Authentication with GDS SSO' do

  context "no existing local user" do
    scenario 'logging in as a user with signin permission' do
      mock_gds_sso_auth('1234')
      visit '/'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      u = User.where(:uid => '1234').first
      expect(u).to be
      expect(u.name).to eq("Test User")
      expect(u.email).to eq("test@example.com")
      expect(u.admin).to be false
    end

    scenario 'logging in as a signon with admin permission sets local admin flag' do
      mock_gds_sso_auth('1234', :permissions => %w(signin admin))
      visit '/'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      u = User.where(:uid => '1234').first
      expect(u).to be
      expect(u.admin).to be true
    end

    scenario 'attempting to log in as a user without signin permission' do
      mock_gds_sso_auth('1234', :permissions => [])
      visit '/'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.failure", :kind => 'GDS Signon', :reason => "You do not have permission to access the app"))

      u = User.where(:uid => '1234').first
      expect(u).to be_nil
    end
  end

  context "with an existing local user" do
    before :each do
      @user = Fabricate(:user, :uid => '1234')
    end

    scenario 'logging in as a user with signin permission' do
      mock_gds_sso_auth('1234')
      visit '/'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      @user.reload
      expect(@user.name).to eq("Test User")
      expect(@user.email).to eq("test@example.com")
      expect(@user.admin).to be false
    end

    scenario 'logging in as a signon with admin permission sets local admin flag' do
      mock_gds_sso_auth('1234', :permissions => %w(signin admin))
      visit '/'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      @user.reload
      expect(@user.admin).to be true
    end

    scenario 'attempting to log in as a user without signin permission' do
      mock_gds_sso_auth('1234', :permissions => [])
      visit '/'

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.failure", :kind => 'GDS Signon', :reason => "You do not have permission to access the app"))

      # shouldn't actually delete the user...
      expect(User.find(@user.id)).to be
    end
  end

  context "session timeout" do
    it "should timeout the session after 8 hours inactivity" do
      mock_gds_sso_auth('1234')

      visit '/'
      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      Timecop.travel((8.hours + 2.minutes).from_now)

      visit '/problems'
      # The flash message indicates we've done the oauth dance again
      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))
    end
  end

  context "respecting the remotely_signed_out flag" do
    before :each do
      @user = Fabricate(:user, :uid => '123456')
    end

    scenario "forcing the user to re-auth against signon when remotely_signed_out is set" do
      log_in(@user)
      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      @user.set_remotely_signed_out!

      # We have to assert we are redirected to the sign_in page.
      # If we just allowed following redirects, it would just do the sign_in dance again against the mock omniauth
      # and leave us back on the homepage logged_in
      page.driver.options[:follow_redirects] = false
      visit "/"
      expect(page.status_code).to eq(302)
      expect(page.response_headers["Location"]).to eq("http://www.example.com/users/sign_in")
    end

    scenario "remotely_signed_out user logs in through SSO" do
      @user.set_remotely_signed_out!
      mock_gds_sso_auth(@user.uid)

      visit "/"
      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", :kind => 'GDS Signon'))

      @user.reload
      expect(@user).not_to be_remotely_signed_out
    end

    after :each do
      page.driver.options[:follow_redirects] = true
    end
  end
end
