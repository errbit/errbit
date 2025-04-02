# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with Google", type: :system do
  before { driven_by(:selenium_chrome_headless) }

  context "sign in via Google with recognized user" do
    let!(:user) { Fabricate(:user, google_uid: "123456789") }

    before { expect(Errbit::Config).to receive(:google_authentication).and_return(true) }

    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(uid: "123456789") }

    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "is expected to sign in user via Google" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
    end
  end

  context "reject unrecognized user" do
    it "is expected to reject unrecognized user" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content("There are no authorized users with Google login")
    end
  end
end
