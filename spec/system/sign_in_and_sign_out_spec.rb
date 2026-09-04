# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in and sign out with email and password", type: :system, retry: 3 do
  let!(:user) { create(:user, password: "password") }

  context "when user successful sign in and sign out" do
    it "is expected to sign in user and sign out" do
      visit root_path

      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))
      expect(page).to have_css('input[name="user[email]"][autocomplete="email"]')
      expect(page).to have_css('input[name="user[password]"][autocomplete="current-password"]')

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

  context "when user exists but password is wrong" do
    it "is expected to reject user with wrong password" do
      visit root_path

      expect(page).to have_content(I18n.t("devise.failure.unauthenticated"))

      fill_in "Email", with: user.email
      fill_in "Password", with: "ohS4eiv4mitiG3Iu1cu3"

      click_button I18n.t("devise.sessions.new.sign_in")

      expect(page).to have_current_path(new_user_session_path)

      expect(page).to have_content(I18n.t("devise.failure.invalid", authentication_keys: "email"))
    end
  end

  it "carries the entered email to the password reset form" do
    visit new_user_session_path

    fill_in "Email", with: user.email
    click_link "forgot it?"

    expect(page).to have_current_path(new_user_password_path, ignore_query: true)
    expect(page).to have_field("Email", with: user.email)
  end

  it "renders the password reset email autocomplete attribute" do
    visit new_user_password_path

    expect(page).to have_css('input[name="user[email]"][autocomplete="email"]')
  end

  it "renders the password reset new-password autocomplete attributes" do
    token = user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token)

    expect(page).to have_css('input[name="user[password]"][autocomplete="new-password"]')
    expect(page).to have_css('input[name="user[password_confirmation]"][autocomplete="new-password"]')
  end

  it "renders the username autocomplete attribute when username authentication is enabled" do
    allow(Errbit::Config).to receive(:user_has_username).and_return(true)
    allow(Devise).to receive(:authentication_keys).and_return([:username])
    allow(User).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap do |resource|
        allow(resource).to receive(:username).and_return(nil)
      end
    end

    visit new_user_session_path

    expect(page).to have_css('input[name="user[username]"][autocomplete="username"]')
  end
end
