# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/.well-known/change-password", type: :system do
  it "redirects an already logged-in user to the change password form" do
    user = create(:user, email: "me@example.com", password: "eidii7EeooVe8ahk")

    visit new_user_session_path

    fill_in "Email", with: "me@example.com"
    fill_in "Password", with: "eidii7EeooVe8ahk"

    click_button I18n.t("devise.sessions.new.sign_in")

    expect(page).to have_text(I18n.t("devise.sessions.signed_in"))

    visit "/.well-known/change-password"

    find_by_id("edit_user")

    expect(page).to have_current_path("/users/#{user.id}/edit")
  end
end
