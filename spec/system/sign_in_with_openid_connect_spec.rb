# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with OpenID Connect", type: :system, retry: 3 do
  before { expect(Errbit::Config).to receive(:oidc_enabled).and_return(true).at_least(:once).times }

  before do
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
      {
        provider: "openid_connect",
        info: {
          email: "me@example.com",
          name: "Jon Snow"
        }
      }
    )
  end

  after { OmniAuth.config.mock_auth[:openid_connect] = nil }

  context "when user is registered" do
    it "is expected to create an account" do
      visit root_path

      click_link "Sign in with OpenID Connect"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "OpenID Connect"))
    end
  end
end
