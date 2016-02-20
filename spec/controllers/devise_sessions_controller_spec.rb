describe Devise::SessionsController, type: 'controller' do
  render_views

  describe "POST /users/sign_in" do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    let(:app)  { Fabricate(:app) }
    let(:user) { Fabricate(:user) }

    it 'redirects to app index page if there are no apps for the user' do
      details = { 'email' => user.email, 'password' => user.password }
      if Errbit::Config.user_has_username
        details['username'] = user.username 
      end

      post :create, user: details
      expect(response).to redirect_to(root_path)
    end

    it 'displays a friendly error when credentials are invalid' do
      details = { 'email' => 'whatever', 'password' => 'somethinginvalid' }
      msg = I18n.t('devise.failure.user.email_invalid')
      if Errbit::Config.user_has_username
        details['username'] = 'somethinginvalid'
        msg = I18n.t('devise.failure.user.username_invalid')
      end
      post :create, user: details
      expect(request.flash["alert"]).to eq(msg)
    end
  end
end
