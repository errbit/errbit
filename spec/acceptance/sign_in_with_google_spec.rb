# frozen_string_literal: true

require "acceptance/acceptance_helper"

RSpec.feature "Sign in with Google with domain validation" do
  background do
    allow(Errbit::Config).to receive(:google_authentication).and_return(true)
    allow(Errbit::Config).to receive(:google_auto_provision).and_return(true)
    allow(Errbit::Config).to receive(:google_authorized_domains).and_return("errbit.example.com")
    Fabricate(:user, google_uid: "nashby")
    visit root_path
  end

  scenario "create an account for recognized user if their account email is from a trusted domain" do
    mock_auth("unknown_but_valid_user")

    click_link "Sign in with Google"
    expect(page).to have_content I18n.t("devise.omniauth_callbacks.success", kind: "Google")
  end

  scenario "don't create an account for user if their account email is from an unauthorized domain" do
    allow(Errbit::Config).to receive(:google_authorized_domains).and_return("example.com")
    mock_auth("unknown_but_invalid_user")

    click_link "Sign in with Google"
    expect(page).to have_text I18n.t("devise.google_login.domain_unauthorized")
  end
end
