require 'spec_helper'

describe Users::SessionsController, type: 'controller' do

  before :each do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET new" do
    it "should redirect to gds oauth" do
      get :new

      expect(response).to redirect_to("/users/auth/gds")
    end
  end

  describe "DELETE destroy" do
    it "should redirect to signon to continue logout there" do
      delete :destroy

      expect(response).to redirect_to("#{GDS::SSO::Config.oauth_root_url}/users/sign_out")
    end
  end
end
