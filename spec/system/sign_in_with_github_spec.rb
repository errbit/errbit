# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with GitHub", type: :system, retry: 3 do
  context "sign in via GitHub with recognized user" do
    let!(:user) { create(:errbit_user, github_login: "biow0lf") }

    before { expect(Errbit::Config).to receive(:github_authentication).and_return(true).twice }

    before { OmniAuth.config.mock_auth[:github] = Faker::Omniauth.github(name: "biow0lf") }

    after { OmniAuth.config.mock_auth[:github] = nil }

    it "is expected to sign in user via GitHub" do
      visit root_path

      click_link "Sign in with GitHub"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "GitHub"))
    end
  end

  context "reject unrecognized user" do
    it "is expected to reject unrecognized user" do
      visit root_path

      click_link "Sign in with GitHub"

      expect(page).to have_content("There are no authorized users with GitHub login")
    end
  end
end
