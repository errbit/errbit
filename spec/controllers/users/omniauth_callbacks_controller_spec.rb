describe Users::OmniauthCallbacksController, type: 'controller' do
  def stub_env_for_github_omniauth(login, token = nil)
    # This a Devise specific thing for functional tests. See https://github.com/plataformatec/devise/issues/closed#issue/608
    request.env["devise.mapping"] = Devise.mappings[:user]
    env = {
      "omniauth.auth" => Hashie::Mash.new(
        :provider => 'github',
        :extra => { :raw_info => { :login => login }},
        :credentials => { :token => token }
      )
    }
    allow(@controller).to receive(:env).and_return(env)
  end

  context 'Linking a GitHub account to a signed in user' do
    before do
      sign_in @user = Fabricate(:user)
    end

    it "should show an error if another user already has that github login" do
      Fabricate(:user, :github_login => "existing_user")
      stub_env_for_github_omniauth("existing_user")
      get :github

      expect(request.flash[:error]).to include('already registered')
      expect(response).to redirect_to(user_path(@user))
    end

    it "should link an authorized GitHub account" do
      stub_env_for_github_omniauth("new_user")
      get :github

      expect(request.flash[:success]).to include('Successfully linked')
      expect(response).to redirect_to(user_path(@user))
    end
  end

  # See spec/acceptance/sign_in_with_github_spec.rb for 'Signing in with github' integration tests.

  def stub_env_for_gds_omniauth(uid, details = {})
    # This a Devise specific thing for functional tests. See https://github.com/plataformatec/devise/issues/closed#issue/608
    request.env["devise.mapping"] = Devise.mappings[:user]
    @stub_omniauth_hash = gds_omniauth_hash_stub(uid, details)
    env = {
      "omniauth.auth" => @stub_omniauth_hash,
    }
    @controller.stub(:env).and_return(env)
  end

  context 'Callback from GDS SSO' do
    before :each do
      stub_env_for_gds_omniauth('1234')
    end

    context "with a valid user" do
      before :each do
        @mock_user = mock_model(User, :clear_remotely_signed_out! => nil)
        User.stub(:find_for_gds_oauth).and_return(@mock_user)

        @controller.stub(:sign_in_and_redirect)
        @controller.stub(:render) # prevent missing template errors due to stubbing sign_in_and_redirect etc.
      end

      it "should create/update a user from the details" do
        User.should_receive(:find_for_gds_oauth).with(@stub_omniauth_hash).and_return(@mock_user)
        get :gds
      end

      it "should clear remotely_signed_out flag on the user" do
        @mock_user.should_receive(:clear_remotely_signed_out!)
        get :gds
      end

      it "should sign in and redirect the user" do
        @controller.should_receive(:sign_in_and_redirect).with(@mock_user, :event => :authentication)
        get :gds
      end
    end

    context "with an invalid user" do
      before :each do
        User.stub(:find_for_gds_oauth).and_return(nil)
      end

      it "should display an error message to the user" do
        get :gds

        expect(response.status).to eq(403)
        expect(response.body).to match("You do not have permission to access the app")
      end
    end
  end
end
