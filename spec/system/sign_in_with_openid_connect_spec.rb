# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with OpenID Connect", type: :system do
  before do
    allow(Errbit::Config).to receive(:oidc_authentication).and_return(true)
    allow(Errbit::Config).to receive(:oidc_site_title).and_return("OpenID Connect")
    allow(Errbit::Config).to receive(:oidc_issuer).and_return("https://issuer.example.com")
    allow(Errbit::Config).to receive(:oidc_auto_provision).and_return(false)
  end

  after { OmniAuth.config.mock_auth[:openid_connect] = nil }

  it "signs in a registered user by issuer and UID" do
    create(:user, oidc_issuer: "https://issuer.example.com", oidc_uid: "subject-1")
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
      provider: "openid_connect", uid: "subject-1",
      info: {email: "user@example.com", email_verified: true, name: "OIDC User"}
    )

    visit root_path
    click_link "Sign in with OpenID Connect"

    expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "OpenID Connect"))
  end

  it "rejects an unknown user by default" do
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
      provider: "openid_connect", uid: "unknown",
      info: {email: "unknown@example.com", email_verified: true}
    )

    visit root_path
    click_link "Sign in with OpenID Connect"

    expect(page).to have_content("There are no authorized users with OpenID Connect login")
  end

  it "does not show the login link when OIDC is disabled" do
    allow(Errbit::Config).to receive(:oidc_authentication).and_return(false)

    visit new_user_session_path

    expect(page).not_to have_link("Sign in with OpenID Connect")
  end
end
