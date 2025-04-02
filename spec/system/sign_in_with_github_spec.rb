# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sign in with GitHub", type: :system do
  it "log in via GitHub with recognized user" do
    Fabricate(:user, github_login: "nashby")

    visit root_path

    click_link "Sign in with GitHub"

    expect(page).to have_content I18n.t("devise.omniauth_callbacks.success", kind: "GitHub")
  end
end
