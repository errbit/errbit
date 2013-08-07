require 'spec_helper'

describe Users::OmniauthCallbacksController do

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
    @controller.stub(:env).and_return(env)
  end

  context 'Linking a GitHub account to a signed in user' do
    before do
      sign_in @user = Fabricate(:user)
    end

    it "should show an error if another user already has that github login" do
      Fabricate(:user, :github_login => "existing_user")
      stub_env_for_github_omniauth("existing_user")
      get :github

      request.flash[:error].should include('already registered')
      response.should redirect_to(user_path(@user))
    end

    it "should link an authorized GitHub account" do
      stub_env_for_github_omniauth("new_user")
      get :github

      request.flash[:success].should include('Successfully linked')
      response.should redirect_to(user_path(@user))
    end
  end

  # See spec/acceptance/sign_in_with_github_spec.rb for 'Signing in with github' integration tests.
end
