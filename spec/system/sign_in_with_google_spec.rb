# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with Google", type: :system, retry: 3 do
  context "when the Google user matches a known Errbit::User" do
    let!(:user) { create(:errbit_user, google_uid: "123456789") }

    before { expect(Errbit::Config).to receive(:google_authentication).and_return(true) }
    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(uid: "123456789") }
    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "signs the user in" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
    end
  end

  context "without a matching Errbit::User" do
    it "rejects the unrecognized Google user" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content("There are no authorized users with Google login")
    end
  end
end
