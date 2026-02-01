# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with Google with auto provision", type: :system, retry: 3 do
  context "create an account for recognized user if they log in" do
    before { Config.google.enabled = true }

    before { Config.google.auto_provision = true }

    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(uid: "123456789") }

    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "is expected to create an account" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
    end
  end
end
