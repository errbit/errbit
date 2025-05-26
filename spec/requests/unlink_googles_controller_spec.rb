# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnlinkGooglesController, type: :request do
  describe "#update" do
    context "when user is logged in" do
      context "when user has access" do

      end

      context "when user has not access" do

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
