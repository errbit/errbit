# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  def stub_env_for_github_omniauth(login, token = nil, email = "user@example.com")
    # This a Devise specific thing for functional tests. See https://github.com/plataformatec/devise/issues/closed#issue/608
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = Hashie::Mash.new(
      provider: "github",
      extra: {raw_info: {login: login, email: email}},
      credentials: {token: token}
    )
  end

  def stub_client_for_github_omniauth(emails = [])
    mock_gh_client = double
    expect(mock_gh_client).to receive(:organizations) { [OpenStruct.new(id: 42), OpenStruct.new(id: 43)] }
    expect(mock_gh_client).to receive(:api_endpoint=)
    allow(mock_gh_client).to receive(:emails) { emails }
    expect(Octokit::Client).to receive(:new) { mock_gh_client }
  end

  context "Linking a GitHub account to a signed in user" do
    before do
      sign_in @user = create(:user)
    end

    it "should show an error if another user already has that GitHub login" do
      create(:user, github_login: "existing_user")
      stub_env_for_github_omniauth("existing_user")
      get :github

      expect(request.flash[:error]).to include("already registered")
      expect(response).to redirect_to(user_path(@user))
    end

    it "should link an authorized GitHub account" do
      stub_env_for_github_omniauth("new_user")
      get :github

      expect(request.flash[:success]).to include("Successfully linked")
      expect(response).to redirect_to(user_path(@user))
    end
  end

  context "Creating a new user via GitHub authentication" do
    before do
      Errbit::Config.github_org_id = 42
    end

    after do
      Errbit::Config.github_org_id = nil
    end

    context "User has valid emails defined" do
      it "should log in the user" do
        stub_env_for_github_omniauth("new_user_with_no_profile_email", nil, nil)
        stub_client_for_github_omniauth([OpenStruct.new(email: "user@example.com", primary: true)])

        get :github

        expect(request.flash[:success]).to include("Successfully authenticated from GitHub account")
        expect(response).to redirect_to(root_path)
      end
    end

    context "User has no email defined" do
      it "should return an error" do
        stub_env_for_github_omniauth("new_user_with_no_profile_email", nil, nil)
        stub_client_for_github_omniauth

        get :github

        expect(request.flash[:error]).to include("Could not retrieve user's email from GitHub")
        expect(response).to redirect_to(user_session_path)
      end
    end
  end

  def stub_env_for_google_omniauth(login, _ = nil)
    # This a Devise specific thing for functional tests. See https://github.com/plataformatec/devise/issues/closed#issue/608
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = Hashie::Mash.new(
      credentials: {
        provider: "google_oauth2"
      },
      info: {email: "#{login}@example.com", name: "John Smith"},
      uid: login
    )
  end

  context "Linking a Google account to a signed in user" do
    before do
      sign_in @user = create(:user)
    end

    it "should show an error if another user already has that google login" do
      create(:user, google_uid: "111111111111111111111")
      stub_env_for_google_omniauth("111111111111111111111")
      get :google_oauth2

      expect(request.flash[:error]).to include("already registered")
      expect(response).to redirect_to(user_path(@user))
    end

    it "should link an authorized Google account" do
      stub_env_for_google_omniauth("111111111111111111112")
      get :google_oauth2

      expect(request.flash[:success]).to include("Successfully linked")
      expect(response).to redirect_to(user_path(@user))
    end
  end

  def stub_env_for_oidc_omniauth(uid, email: "#{uid}@example.com", name: "John Smith", email_verified: false)
    # This a Devise specific thing for functional tests. See https://github.com/plataformatec/devise/issues/closed#issue/608
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = Hashie::Mash.new(
      provider: "openid_connect",
      info: {email: email, email_verified: email_verified, name: name},
      uid: uid
    )
  end

  context "Linking an OpenID Connect account to a signed in user" do
    before do
      sign_in @user = create(:user)
    end

    it "should show an error if another user already has that OpenID Connect login" do
      create(:user, oidc_uid: "existing-subject")
      stub_env_for_oidc_omniauth("existing-subject")
      get :openid_connect

      expect(request.flash[:error]).to include("already registered")
      expect(response).to redirect_to(user_path(@user))
    end

    it "should link an authorized OpenID Connect account" do
      stub_env_for_oidc_omniauth("new-subject")
      get :openid_connect

      expect(request.flash[:success]).to include("Successfully linked")
      expect(@user.reload.oidc_uid).to eq("new-subject")
      expect(response).to redirect_to(user_path(@user))
    end
  end

  context "Signing in via OpenID Connect" do
    it "should sign in a user that already has the identity linked" do
      user = create(:user, oidc_uid: "known-subject")
      stub_env_for_oidc_omniauth("known-subject")
      get :openid_connect

      expect(controller.current_user).to eq(user)
    end

    it "should refuse a response that carries no subject" do
      unlinked = create(:user)
      stub_env_for_oidc_omniauth(nil, email: unlinked.email)
      get :openid_connect

      expect(controller.current_user).to be_nil
      expect(request.flash[:error]).to include("did not identify the account")
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when auto provisioning is disabled" do
      it "should refuse an unknown subject" do
        allow(Errbit::Config).to receive(:oidc_auto_provision).and_return(false)
        stub_env_for_oidc_omniauth("unknown-subject")
        get :openid_connect

        expect(request.flash[:error]).to include("no authorized users")
        expect(response).to redirect_to(new_user_session_path)
      end

      it "should not claim an account with the same email" do
        existing = create(:user, email: "existing@example.com")
        allow(Errbit::Config).to receive(:oidc_auto_provision).and_return(false)
        stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: true)
        get :openid_connect

        expect(existing.reload.oidc_uid).to be_nil
        expect(controller.current_user).to be_nil
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when auto provisioning is enabled" do
      before do
        allow(Errbit::Config).to receive(:oidc_auto_provision).and_return(true)
        allow(Errbit::Config).to receive(:oidc_authorized_domains).and_return(nil)
      end

      it "should create a user for an unknown subject" do
        stub_env_for_oidc_omniauth("unknown-subject", email: "new@example.com")
        get :openid_connect

        user = User.where(email: "new@example.com").first
        expect(user).to be_present
        expect(user.oidc_uid).to eq("unknown-subject")
        expect(user).not_to be_admin
        expect(controller.current_user).to eq(user)
      end

      it "should refuse a response that carries no email" do
        stub_env_for_oidc_omniauth("unknown-subject", email: nil)

        expect { get :openid_connect }.not_to change(User, :count)
        expect(request.flash[:error]).to include("did not provide an email address")
        expect(response).to redirect_to(new_user_session_path)
      end

      it "should refuse an email outside the authorized domains" do
        allow(Errbit::Config).to receive(:oidc_authorized_domains).and_return("example.org")
        stub_env_for_oidc_omniauth("unknown-subject", email: "someone@example.com")

        expect { get :openid_connect }.not_to change(User, :count)
        expect(request.flash[:error]).to include("not authorized")
        expect(response).to redirect_to(new_user_session_path)
      end

      it "should match the authorized domains against a mixed case email" do
        allow(Errbit::Config).to receive(:oidc_authorized_domains).and_return("Example.COM, example.org")
        stub_env_for_oidc_omniauth("unknown-subject", email: "Someone@Example.COM")
        get :openid_connect

        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq("someone@example.com")
      end

      context "and an account already has that email address" do
        let!(:existing) { create(:user, email: "existing@example.com") }

        it "should claim it when the provider verified the address" do
          stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: true)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to eq("unknown-subject")
          expect(controller.current_user).to eq(existing)
        end

        it "should claim it through a mixed case email claim" do
          stub_env_for_oidc_omniauth("unknown-subject", email: "Existing@Example.COM", email_verified: true)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to eq("unknown-subject")
          expect(controller.current_user).to eq(existing)
        end

        it "should refuse when the provider did not verify the address" do
          stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: false)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to be_nil
          expect(controller.current_user).to be_nil
          expect(request.flash[:error]).to include("already exists")
          expect(response).to redirect_to(new_user_session_path)
        end

        it "should refuse an admin account even on a verified address" do
          existing.update!(admin: true)
          stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: true)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to be_nil
          expect(controller.current_user).to be_nil
          expect(request.flash[:error]).to include("already exists")
        end

        it "should refuse when another OpenID Connect identity already answers for it" do
          existing.update!(oidc_uid: "other-subject")
          stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: true)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to eq("other-subject")
          expect(controller.current_user).to be_nil
          expect(request.flash[:error]).to include("already exists")
        end

        it "should refuse when a GitHub account is linked to it" do
          existing.update!(github_login: "someone", github_oauth_token: "token")
          stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: true)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to be_nil
          expect(existing.github_oauth_token).to eq("token")
          expect(controller.current_user).to be_nil
        end

        it "should refuse when a Google account is linked to it" do
          existing.update!(google_uid: "google-subject")
          stub_env_for_oidc_omniauth("unknown-subject", email: "existing@example.com", email_verified: true)

          expect { get :openid_connect }.not_to change(User, :count)
          expect(existing.reload.oidc_uid).to be_nil
          expect(controller.current_user).to be_nil
        end
      end
    end
  end

  # See spec/acceptance/sign_in_with_github_spec.rb for 'Signing in with GitHub' integration tests.
end
