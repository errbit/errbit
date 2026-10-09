# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniAuth passthru", type: :request do
  # An identity provider's dashboard links at the authorize path with a GET.
  # OmniAuth runs the request phase on POST only, so without a route and an
  # action of our own the link answers "Not found. Authentication passthru."
  describe "GET the authorize path" do
    it "answers with a form that posts the request phase" do
      get "/users/auth/openid_connect"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="/users/auth/openid_connect"')
      expect(response.body).to include('method="post"')
      expect(response.body).to include('getElementById("omniauth_passthru").submit()')
    end

    # The post is what omniauth-rails_csrf_protection validates, so the form
    # is worthless without the token. Forgery protection is off in the test
    # environment, hence the explicit switch.
    it "carries a CSRF token" do
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      get "/users/auth/openid_connect"

      expect(response.body).to include("authenticity_token")
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    it "tolerates the trailing slash a provider may append" do
      get "/users/auth/openid_connect/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="/users/auth/openid_connect"')
    end

    it "works for the other providers too" do
      get "/users/auth/github"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="/users/auth/github"')
    end

    it "does not invent an endpoint for a provider that is not configured" do
      get "/users/auth/saml"

      expect(response).to have_http_status(:not_found)
    end
  end
end
