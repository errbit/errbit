# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :request do
  describe "#index" do
    context "when user is logged in" do
      context "when user is an admin" do
        let!(:user_1) { create(:user, name: "Jon Snow", admin: true) }

        let!(:user_2) { create(:user, name: "Tyrion Lannister") }

        before { sign_in(user_1) }

        before { get users_path }

        it "is expected to render template index with status ok" do
          expect(response).to render_template(:index)

          expect(response).to have_http_status(:ok)

          expect(assigns(:users)).to eq([user_1, user_2])
        end
      end

      context "when user is not an admin" do
        let(:user) { create(:user, name: "Tyrion Lannister", admin: false) }

        before { sign_in(user) }

        before { get users_path }

        it "is expected to render template index with status ok" do
          expect(response).to render_template(:index)

          expect(response).to have_http_status(:ok)

          expect(assigns(:users)).to eq([user])
        end
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

  describe "#show" do
    context "when user is logged in" do
      # TODO: write
    end

    context "when user is not logged in" do
      let!(:user) { create(:user) }

      before { get user_path(user) }

      it "is expected to redirect to new user session url with status found" do
        expect(response).to redirect_to(new_user_session_url)

        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "#new" do
    context "when user is logged in" do
      # TODO: write
    end

    context "when user is not logged in" do
      before { get new_user_path }

      it "is expected to redirect to new user session url with status found" do
        expect(response).to redirect_to(new_user_session_url)

        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "#edit" do
    context "when user is logged in" do
      # TODO: write
    end

    context "when user is not logged in" do
      let!(:user) { create(:user) }

      before { get edit_user_path(user) }

      it "is expected to redirect to new user session url with status found" do
        expect(response).to redirect_to(new_user_session_url)

        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "#create" do
    context "when user is logged in" do
      # TODO: write
    end

    context "when user is not logged in" do
      # TODO: write
    end
  end

  describe "#update" do
    context "when user is logged in" do
      # TODO: write
    end

    context "when user is not logged in" do
      # TODO: write
    end
  end
end
