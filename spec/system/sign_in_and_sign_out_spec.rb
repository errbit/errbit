# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in and sign out with email and password", type: :system do
  before { driven_by(:selenium_chrome_headless) }

  context "when user successful sign in and sign out" do
    it "is expected to sign in user and sign out" do
      user = Fabricate(:user)

      visit root_path

      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))

      fill_in "Email", with: user.email
      fill_in "Password", with: "password"

      click_button I18n.t("devise.sessions.new.sign_in")

      expect(page).to have_content(I18n.t("devise.sessions.signed_in"))

      expect(page).to have_current_path(root_path)

      click_link I18n.t("shared.session.sign_out")

      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))

      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
