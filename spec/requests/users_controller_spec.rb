# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :request do
  describe "#index" do
    context "when user is logged in" do
      context "as an admin" do
        let!(:current_user) { create(:user, name: "Jon Snow", admin: true) }
        let!(:errbit_a) { create(:errbit_user, name: "Aaa") }
        let!(:errbit_b) { create(:errbit_user, name: "Zzz") }

        before { sign_in(current_user) }
        before { get users_path }

        it "renders index with status ok and all Errbit::Users" do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:users)).to eq([errbit_a, errbit_b])
        end
      end

      context "as a non-admin (sees only themselves via bson_id link)" do
        let!(:current_user) { create(:user, admin: false) }
        let!(:linked_errbit_user) { create(:errbit_user, bson_id: current_user._id.to_s) }
        let!(:other_errbit_user) { create(:errbit_user) }

        before { sign_in(current_user) }
        before { get users_path }

        it "renders index with status ok and only the linked Errbit::User" do
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
          expect(assigns(:users)).to eq([linked_errbit_user])
        end
      end
    end

    context "when user is not logged in" do
      before { get users_path }

      it "redirects to sign in" do
        expect(response).to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:found)
        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#show" do
    context "when user is logged in" do
      context "as admin" do
        let(:current_user) { create(:user, admin: true) }
        let(:user) { create(:errbit_user, admin: false) }

        before { sign_in(current_user) }
        before { get user_path(user) }

        it "renders show" do
          expect(response).to render_template(:show)
          expect(response).to have_http_status(:ok)
          expect(assigns(:user)).to eq(user)
        end
      end

      context "as non-admin (no bson_id link to the record)" do
        let(:current_user) { create(:user, admin: false) }
        let(:user) { create(:errbit_user, admin: false) }

        before { sign_in(current_user) }
        before { get user_path(user) }

        it "redirects to root with not-authorized flash" do
          expect(response).to redirect_to(root_path)
          expect(response).to have_http_status(:found)
          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      let!(:user) { create(:errbit_user) }

      before { get user_path(user) }

      it "redirects to sign in" do
        expect(response).to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:found)
        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#new" do
    context "when user is logged in" do
      context "as admin" do
        let(:current_user) { create(:user, admin: true) }

        before { sign_in(current_user) }
        before { get new_user_path }

        it "renders new" do
          expect(response).to render_template(:new)
          expect(response).to have_http_status(:ok)
          expect(assigns(:user).new_record?).to eq(true)
        end
      end

      context "as non-admin" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }
        before { get new_user_path }

        it "redirects to root with not-authorized flash" do
          expect(response).to redirect_to(root_path)
          expect(response).to have_http_status(:found)
          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      before { get new_user_path }

      it "redirects to sign in" do
        expect(response).to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "#edit" do
    context "when user is logged in" do
      context "as admin" do
        let(:current_user) { create(:user, admin: true) }
        let!(:user) { create(:errbit_user, admin: false) }

        before { sign_in(current_user) }
        before { get edit_user_path(user) }

        it "renders edit" do
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:ok)
          expect(assigns(:user)).to eq(user)
        end
      end

      context "as non-admin (no bson_id link)" do
        let(:current_user) { create(:user, admin: false) }
        let(:user) { create(:errbit_user, admin: false) }

        before { sign_in(current_user) }
        before { get edit_user_path(user) }

        it "redirects to root with not-authorized flash" do
          expect(response).to redirect_to(root_path)
          expect(response).to have_http_status(:found)
        end
      end
    end
  end

  describe "#create" do
    context "when user is logged in" do
      context "as admin with valid params" do
        let(:current_user) { create(:user, admin: true) }
        let(:email) { Faker::Internet.unique.email }
        let(:password) { Faker::Internet.password }
        let(:name) { Faker::Name.unique.name }

        before { sign_in(current_user) }

        before do
          expect {
            post users_path,
              params: {user: {email: email, name: name, password: password, password_confirmation: password, admin: true}}
          }.to change(Errbit::User, :count).by(1)
        end

        it "creates a new Errbit::User and redirects to it" do
          expect(response).to redirect_to(user_path(assigns(:user)))
          expect(response).to have_http_status(:found)
          expect(request.flash[:success]).to eq(I18n.t("users.create.success", name: name))
          expect(assigns(:user).email).to eq(email)
          expect(assigns(:user).name).to eq(name)
          expect(assigns(:user).admin).to eq(true)
        end
      end

      context "as admin with invalid params" do
        let(:current_user) { create(:user, admin: true) }

        before { sign_in(current_user) }

        before do
          expect {
            post users_path,
              params: {user: {email: "", name: Faker::Name.unique.name, password: "secret123", password_confirmation: "secret123", admin: true}}
          }.not_to change(Errbit::User, :count)
        end

        it "renders new" do
          expect(response).to render_template(:new)
          expect(response).to have_http_status(:ok)
        end
      end

      context "as non-admin" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before do
          expect {
            post users_path,
              params: {user: {email: "a@b.com", name: "X", password: "secret123", password_confirmation: "secret123", admin: true}}
          }.not_to change(Errbit::User, :count)
        end

        it "redirects to root with not-authorized flash" do
          expect(response).to redirect_to(root_path)
          expect(response).to have_http_status(:found)
        end
      end
    end
  end

  describe "#update" do
    context "as admin with valid params" do
      let(:current_user) { create(:user, admin: true) }
      let(:user) { create(:errbit_user, admin: true, name: "Jon Snow") }

      before { sign_in(current_user) }

      before do
        patch user_path(user), params: {user: {name: "Tyrion Lannister", admin: false}}
      end

      it "updates the user and redirects" do
        expect(response).to redirect_to(user_path(user))
        expect(response).to have_http_status(:found)
        expect(request.flash[:success]).to eq(I18n.t("users.update.success", name: user.reload.name))
      end
    end

    context "as admin with invalid params" do
      let(:current_user) { create(:user, admin: true) }
      let(:user) { create(:errbit_user) }

      before { sign_in(current_user) }
      before { patch user_path(user), params: {user: {name: ""}} }

      it "renders edit" do
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:ok)
      end
    end

    context "as non-admin (no bson_id link)" do
      let(:current_user) { create(:user, admin: false) }
      let(:user) { create(:errbit_user, admin: false, name: "Jon Snow") }

      before { sign_in(current_user) }
      before { patch user_path(user), params: {user: {name: "Renamed", admin: true}} }

      it "redirects to root with not-authorized flash" do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "#destroy" do
    context "as admin destroying another user" do
      let(:current_user) { create(:user, admin: true) }
      let!(:user) { create(:errbit_user, admin: false) }

      before { sign_in(current_user) }

      it "calls Errbit::UserDestroy and removes the user" do
        expect(Errbit::UserDestroy).to receive(:new).with(user).and_call_original

        expect { delete user_path(user) }.to change(Errbit::User, :count).by(-1)

        expect(response).to redirect_to(users_path)
        expect(response).to have_http_status(:found)
        expect(request.flash[:success]).to eq(I18n.t("users.destroy.success", name: user.name))
      end
    end

    context "as non-admin destroying another user" do
      let(:current_user) { create(:user, admin: false) }
      let!(:user) { create(:errbit_user, admin: true) }

      before { sign_in(current_user) }

      it "does not call Errbit::UserDestroy and redirects to root" do
        expect(Errbit::UserDestroy).not_to receive(:new)

        expect { delete user_path(user) }.not_to change(Errbit::User, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "trying to destroy themselves (via bson_id link)" do
      let(:current_user) { create(:user) }
      let!(:linked_errbit_user) { create(:errbit_user, bson_id: current_user._id.to_s) }

      before { sign_in(current_user) }

      it "blocks self-destroy with an error flash" do
        expect(Errbit::UserDestroy).not_to receive(:new)

        expect { delete user_path(linked_errbit_user) }.not_to change(Errbit::User, :count)

        expect(response).to redirect_to(users_path)
        expect(request.flash[:error]).to eq(I18n.t("users.destroy.error"))
      end
    end

    context "when user is not logged in" do
      let!(:user) { create(:errbit_user) }

      before { delete user_path(user) }

      it "redirects to sign in" do
        expect(response).to redirect_to(new_user_session_path)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
