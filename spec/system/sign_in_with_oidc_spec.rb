# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with OpenID Connect", type: :system, retry: 3 do
  def mock_oidc_auth(uid:, email:, email_verified: false)
    OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: uid,
      info: {email: email, email_verified: email_verified, name: Faker::Name.unique.name}
    )
  end

  before { allow(Errbit::Config).to receive(:oidc_authentication).and_return(true) }

  after { OmniAuth.config.mock_auth[:openid_connect] = nil }

  context "sign in with a linked identity" do
    let!(:user) { create(:user, oidc_uid: "subject-123") }

    before do
      OmniAuth.config.mock_auth[:openid_connect] =
        mock_oidc_auth(uid: "subject-123", email: user.email)
    end

    it "is expected to sign in the user" do
      visit root_path

      click_link "Sign in with #{Errbit::Config.oidc_site_title}"

      expect(page).to have_content(
        I18n.t("devise.omniauth_callbacks.success", kind: Errbit::Config.oidc_site_title)
      )
    end
  end

  context "reject an unknown identity" do
    before { allow(Errbit::Config).to receive(:oidc_auto_provision).and_return(false) }

    before do
      OmniAuth.config.mock_auth[:openid_connect] =
        mock_oidc_auth(uid: "subject-456", email: "stranger@example.com")
    end

    it "is expected to reject the user" do
      visit root_path

      click_link "Sign in with #{Errbit::Config.oidc_site_title}"

      expect(page).to have_content("There are no authorized users with")
    end
  end

  context "with auto provision" do
    before { allow(Errbit::Config).to receive(:oidc_auto_provision).and_return(true) }

    # Stubbed rather than left to .env.default, so the examples below do not
    # quietly depend on what an installation happens to allow.
    before { allow(Errbit::Config).to receive(:oidc_authorized_domains).and_return(nil) }

    context "and no account with that email address" do
      before do
        OmniAuth.config.mock_auth[:openid_connect] =
          mock_oidc_auth(uid: "subject-789", email: "newcomer@example.com")
      end

      it "is expected to create an account" do
        visit root_path

        click_link "Sign in with #{Errbit::Config.oidc_site_title}"

        expect(page).to have_content(
          I18n.t("devise.omniauth_callbacks.success", kind: Errbit::Config.oidc_site_title)
        )

        expect(User.where(email: "newcomer@example.com").first.oidc_uid).to eq("subject-789")
      end
    end

    # The one example that drives a real OmniAuth::AuthHash through the claim
    # path, so the suite notices if email_verified ever stops arriving in the
    # info hash and the guard silently swallows every claim.
    context "and an account with that email address the provider verified" do
      let!(:user) { create(:user, email: "known@example.com") }

      before do
        OmniAuth.config.mock_auth[:openid_connect] =
          mock_oidc_auth(uid: "subject-abc", email: "known@example.com", email_verified: true)
      end

      it "is expected to claim it" do
        visit root_path

        click_link "Sign in with #{Errbit::Config.oidc_site_title}"

        expect(page).to have_content(
          I18n.t("devise.omniauth_callbacks.success", kind: Errbit::Config.oidc_site_title)
        )

        expect(user.reload.oidc_uid).to eq("subject-abc")
      end
    end

    context "and an account with that email address the provider did not verify" do
      let!(:user) { create(:user, email: "taken@example.com") }

      before do
        OmniAuth.config.mock_auth[:openid_connect] =
          mock_oidc_auth(uid: "subject-789", email: "taken@example.com")
      end

      it "is expected to refuse rather than claim it" do
        visit root_path

        click_link "Sign in with #{Errbit::Config.oidc_site_title}"

        expect(page).to have_content("already exists")

        expect(user.reload.oidc_uid).to be_nil
      end
    end

    context "and an email address outside the authorized domains" do
      before do
        allow(Errbit::Config).to receive(:oidc_authorized_domains).and_return("example.org")

        OmniAuth.config.mock_auth[:openid_connect] =
          mock_oidc_auth(uid: "subject-789", email: "outsider@example.com")
      end

      it "is expected to refuse the user" do
        visit root_path

        click_link "Sign in with #{Errbit::Config.oidc_site_title}"

        expect(page).to have_text(I18n.t("devise.oidc_login.domain_unauthorized"))

        expect(User.where(email: "outsider@example.com").first).to be_nil
      end
    end
  end
end
