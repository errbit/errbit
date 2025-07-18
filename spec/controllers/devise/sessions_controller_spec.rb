# frozen_string_literal: true

require "rails_helper"

RSpec.describe Devise::SessionsController, type: :controller do
  render_views

  describe "POST /users/sign_in" do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:errbit_user]
    end

    let(:app) { create(:errbit_app) }

    let!(:user) { create(:errbit_user, password: "password") }

    it "redirects to app index page if there are no apps for the user" do
      post :create, params: {errbit_user: {email: user.email, password: "password"}}

      expect(response).to redirect_to(root_path)
    end

    it "displays a friendly error when credentials are invalid" do
      post :create, params: {errbit_user: {email: "whatever", password: "somethinginvalid"}}

      expect(request.flash["alert"]).to eq(I18n.t("devise.failure.not_found_in_database", authentication_keys: "Email"))
    end
  end
end
