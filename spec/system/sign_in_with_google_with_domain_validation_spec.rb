# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with Google with domain validation", type: :system, retry: 3 do
  before { expect(Errbit::Config).to receive(:google_authentication).and_return(true).at_least(:once).times }
  before { expect(Errbit::Config).to receive(:google_auto_provision).and_return(true) }
  before { expect(Errbit::Config).to receive(:google_authorized_domains).and_return("example.com").twice }

  context "with a Google email from an authorized domain" do
    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(email: "me@example.com", uid: "123456789") }
    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "auto-provisions the Errbit::User and signs them in" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
    end
  end

  context "with a Google email from an unauthorized domain" do
    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(email: "me@mail.example.com", uid: "123456789") }
    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "does not create an account and shows the domain-unauthorized error" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_text(I18n.t("devise.google_login.domain_unauthorized"))
    end
  end
end
