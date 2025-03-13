describe Devise::SessionsController, type: "controller" do
  render_views

  describe "POST /users/sign_in" do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    let(:app)  { Fabricate(:app) }
    let(:user) { Fabricate(:user) }

    it "redirects to app index page if there are no apps for the user" do
      post :create, params: { user: { "email" => user.email, "password" => user.password } }
      expect(response).to redirect_to(root_path)
    end

    it "displays a friendly error when credentials are invalid" do
      post :create, params: { user: { "email" => "whatever", "password" => "somethinginvalid" } }
      expect(request.flash["alert"]).to eq(I18n.t "devise.failure.user.email_invalid")
    end
  end
end
