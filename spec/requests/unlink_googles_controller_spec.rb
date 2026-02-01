# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnlinkGooglesController, type: :request do
  describe "#update" do
    context "when user is logged in" do
      context "when user has access" do
        let!(:current_user) { create(:user, google_uid: "google-uid") }

        before { sign_in(current_user) }

        before { patch user_unlink_google_path(current_user) }

        it "is expected to unlink github for a user with status found" do
          expect(response).to redirect_to(user_path(assigns(:user)))

          expect(response).to have_http_status(:found)

          expect(assigns(:user).google_uid).to eq(nil)

          expect(request.flash[:success]).to eq("Successfully unlinked Google account!")
        end
      end

      context "when user has not access" do
        let!(:current_user) { create(:user, admin: false) }

        let!(:user) { create(:user) }

        before { sign_in(current_user) }

        before { patch user_unlink_google_path(user) }

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
        end
      end
    end

    context "when user is not logged in" do
      let(:user) { create(:user) }

      before { patch user_unlink_google_path(user) }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)
      end
    end
  end
end
