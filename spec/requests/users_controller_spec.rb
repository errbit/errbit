# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :request do
  describe "#index" do
    context "when user is logged in" do
      context "when user is an admin" do
        let(:user) { create(:user, admin: true) }

        before { sign_in(user) }

        before { get users_path }

        it "is expected to render template index with status ok" do
          expect(response).to render_template(:index)

          expect(response).to have_http_status(:ok)
        end
      end

      context "when user is not an admin" do

      end
    end

    context "when user is not logged in" do
      before { get users_path }

      it "is expected to redirect to new user session url with status found" do
        expect(response).to redirect_to(new_user_session_url)

        expect(response).to have_http_status(:found)
      end
    end
  end
end
