describe Users::OmniauthCallbacksController, type: "controller" do
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
      sign_in @user = Fabricate(:user)
    end

    it "should show an error if another user already has that github login" do
      Fabricate(:user, github_login: "existing_user")
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

  context "Creating a new user via Github authentication" do
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

  def stub_env_for_google_omniauth(login, _token = nil)
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
      sign_in @user = Fabricate(:user)
    end

    it "should show an error if another user already has that google login" do
      Fabricate(:user, google_uid: "111111111111111111111")
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

  # See spec/acceptance/sign_in_with_github_spec.rb for 'Signing in with github' integration tests.
end
