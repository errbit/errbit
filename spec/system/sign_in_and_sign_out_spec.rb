# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in and sign out with email and password", type: :system, retry: 3 do
  let!(:user) { create(:errbit_user, password: "password") }

  context "when user signs in then signs out" do
    it "signs the user in, then signs them out" do
      visit root_path

      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))

      fill_in "Email", with: user.email
      fill_in "Password", with: "password"

      click_button I18n.t("devise.sessions.new.sign_in")

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("devise.sessions.signed_in"))

      click_link I18n.t("shared.session.sign_out")

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))
    end
  end

  context "when user exists but the password is wrong" do
    it "rejects the user with the invalid-credentials flash" do
      visit root_path

      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))

      fill_in "Email", with: user.email
      fill_in "Password", with: "ohS4eiv4mitiG3Iu1cu3"

      click_button I18n.t("devise.sessions.new.sign_in")

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content(I18n.t("devise.failure.invalid", authentication_keys: "email"))
    end
  end
end
