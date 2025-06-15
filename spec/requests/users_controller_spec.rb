# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :request do
  before { I18n.locale = "pt-BR" }

  describe "#index" do
    context "when user is logged in" do
      context "when user has access" do
        let!(:current_user) { create(:user, name: "Jon Snow", admin: true) }

        let!(:user) { create(:user, name: "Tyrion Lannister") }

        before { sign_in(current_user) }

        before { get users_path }

        it "is expected to render template index with status ok" do
          expect(response).to render_template(:index)

          expect(response).to have_http_status(:ok)

          expect(assigns(:users)).to eq([current_user, user])
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { get users_path }

        it "is expected to render template index with status ok" do
          expect(response).to render_template(:index)

          expect(response).to have_http_status(:ok)

          expect(assigns(:users)).to eq([current_user])
        end
      end
    end

    context "when user is not logged in" do
      before { get users_path }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#show" do
    context "when user is logged in" do
      context "when user has access" do
        let(:current_user) { create(:user, admin: true) }

        let(:user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { get user_path(user) }

        it "is expected to render template show with status ok" do
          expect(response).to render_template(:show)

          expect(response).to have_http_status(:ok)

          expect(assigns(:user)).to eq(user)
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        let(:user) { create(:user, admin: false) }

        before { get user_path(user) }

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      let!(:user) { create(:user) }

      before { get user_path(user) }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#new" do
    context "when user is logged in" do
      context "when user has access" do
        let(:current_user) { create(:user, admin: true) }

        before { sign_in(current_user) }

        before { get new_user_path }

        it "is expected to render template new with status ok" do
          expect(response).to render_template(:new)

          expect(response).to have_http_status(:ok)

          expect(assigns(:user).new_record?).to eq(true)
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { get new_user_path }

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      before { get new_user_path }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#edit" do
    context "when user is logged in" do
      context "when user has access" do
        let(:current_user) { create(:user, admin: true) }

        let!(:user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { get edit_user_path(user) }

        it "is expected to render template edit with status ok" do
          expect(response).to render_template(:edit)

          expect(response).to have_http_status(:ok)

          expect(assigns(:user)).to eq(user)
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        let(:user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { get edit_user_path(user) }

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      let(:user) { create(:user) }

      before { get edit_user_path(user) }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#create" do
    context "when user is logged in" do
      context "when user has access" do
        context "when new record is valid" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          let(:email) { Faker::Internet.unique.email }

          let(:password) { Faker::Internet.password }

          let(:name) { Faker::Name.unique.name }

          before do
            expect do
              post users_path,
                params: {
                  user: {
                    email: email,
                    name: name,
                    password: password,
                    password_confirmation: password,
                    admin: true
                  }
                }
            end.to change(User, :count).by(1)
          end

          it "is expected to create a new user with status found" do
            expect(response).to redirect_to(user_path(assigns(:user)))

            expect(response).to have_http_status(:found)

            expect(request.flash[:success]).to eq(I18n.t("users.create.success", name: name))

            expect(assigns(:user).email).to eq(email)

            expect(assigns(:user).name).to eq(name)

            expect(assigns(:user).admin).to eq(true)
          end
        end

        context "when new record is not valid" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          let(:email) { "" }

          let(:password) { Faker::Internet.password }

          let(:name) { Faker::Name.unique.name }

          before do
            expect do
              post users_path,
                params: {
                  user: {
                    email: email,
                    name: name,
                    password: password,
                    password_confirmation: password,
                    admin: true
                  }
                }
            end.not_to change(User, :count)
          end

          it "is expected to render template new with status ok" do
            expect(response).to render_template(:new)

            expect(response).to have_http_status(:ok)
          end
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        let(:email) { Faker::Internet.unique.email }

        let(:password) { Faker::Internet.password }

        let(:name) { Faker::Name.unique.name }

        before do
          expect do
            post users_path,
              params: {
                user: {
                  email: email,
                  name: name,
                  password: password,
                  password_confirmation: password,
                  admin: true
                }
              }
          end.not_to change(User, :count)
        end

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      let(:email) { Faker::Internet.unique.email }

      let(:password) { Faker::Internet.password }

      let(:name) { Faker::Name.unique.name }

      before do
        expect do
          post users_path,
            params: {
              user: {
                email: email,
                name: name,
                password: password,
                password_confirmation: password,
                admin: true
              }
            }
        end.not_to change(User, :count)
      end

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#update" do
    context "when user is logged in" do
      context "when user has access" do
        context "when record is valid" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          let(:user) { create(:user, admin: true, name: "Jon Snow") }

          before do
            patch user_path(user),
              params: {
                user: {
                  name: "Tyrion Lannister",
                  admin: false
                }
              }
          end

          it "is expected to redirect to user path user with status ok" do
            expect(response).to redirect_to(user_path(user))

            expect(response).to have_http_status(:found)

            expect(request.flash[:success]).to eq(I18n.t("users.update.success", name: user.reload.name))
          end
        end

        context "when record is not valid" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          let(:user) { create(:user) }

          before do
            patch user_path(user),
              params: {
                user: {
                  name: ""
                }
              }
          end

          it "is expected to render template new with status ok" do
            expect(response).to render_template(:edit)

            expect(response).to have_http_status(:ok)
          end
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        let(:user) { create(:user, admin: false, name: "Jon Snow") }

        before do
          patch user_path(user),
            params: {
              user: {
                name: "Tyrion Lannister",
                admin: true
              }
            }
        end

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      let(:user) { create(:user) }

      before do
        patch user_path(user),
          params: {
            user: {
              name: Faker::Name.unique.name
            }
          }
      end

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end

  describe "#destroy" do
    context "when user is logged in" do
      context "when user has access" do
        let(:current_user) { create(:user, admin: true) }

        let!(:user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { expect(UserDestroy).to receive(:new).with(user).and_call_original }

        before { expect { delete user_path(user) }.to change(User, :count).by(-1) }

        it "is expected to redirect to users path with status found" do
          expect(response).to redirect_to(users_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:success]).to eq(I18n.t("controllers.users.flash.destroy.success", name: user.name))
        end
      end

      context "when user has not access" do
        let(:current_user) { create(:user, admin: false) }

        let!(:user) { create(:user, admin: true) }

        before { sign_in(current_user) }

        before { expect(UserDestroy).not_to receive(:new) }

        before { expect { delete user_path(user) }.not_to change(User, :count) }

        it "is expected to redirect to users path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq(I18n.t("controllers.application.user_not_authorized"))
        end
      end
    end

    context "when user is not logged in" do
      let(:user) { create(:user) }

      before { delete user_path(user) }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)

        expect(request.flash[:alert]).to eq(I18n.t("devise.failure.unauthenticated"))
      end
    end
  end
end
