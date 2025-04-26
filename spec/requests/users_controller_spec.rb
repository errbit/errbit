# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :request do
  describe "#index" do
    context "when user is logged in" do
      context "when user is an admin" do
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

      context "when user is not an admin" do
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
      end
    end
  end

  describe "#show" do
    context "when user is logged in" do
      context "when user is an admin" do
        context "when admin looking on himself" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          before { get user_path(current_user) }

          it "is expected to render template show with status ok" do
            expect(response).to render_template(:show)

            expect(response).to have_http_status(:ok)

            expect(assigns(:user)).to eq(current_user)
          end
        end

        context "when admin looking on another admin" do
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

        context "when admin looking on another user" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          let(:user) { create(:user, admin: false) }

          before { get user_path(user) }

          it "is expected to render template show with status ok" do
            expect(response).to render_template(:show)

            expect(response).to have_http_status(:ok)

            expect(assigns(:user)).to eq(user)
          end
        end
      end

      context "when user is not an admin" do
        context "when user is looking in himself" do
          let(:current_user) { create(:user, admin: false) }

          before { sign_in(current_user) }

          before { get user_path(current_user) }

          it "is expected to render template show with status ok" do
            expect(response).to render_template(:show)

            expect(response).to have_http_status(:ok)

            expect(assigns(:user)).to eq(current_user)
          end
        end

        context "when user is looking on another user" do
          let(:current_user) { create(:user, admin: false) }

          before { sign_in(current_user) }

          let(:user) { create(:user, admin: false) }

          before { get user_path(user) }

          it "is expected to redirect to root path with status found" do
            expect(response).to redirect_to(root_path)

            expect(response).to have_http_status(:found)

            expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
          end
        end

        context "when user looking on admin" do
          let(:current_user) { create(:user, admin: false) }

          let(:user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          before { get user_path(user) }

          it "is expected to redirect to root path with status found" do
            expect(response).to redirect_to(root_path)

            expect(response).to have_http_status(:found)

            expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
          end
        end
      end
    end

    context "when user is not logged in" do
      let!(:user) { create(:user) }

      before { get user_path(user) }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "#new" do
    context "when user is logged in" do
      context "when user is an admin" do
        let(:current_user) { create(:user, admin: true) }

        before { sign_in(current_user) }

        before { get new_user_path }

        it "is expected to render template new with status ok" do
          expect(response).to render_template(:new)

          expect(response).to have_http_status(:ok)

          expect(assigns(:user).new_record?).to eq(true)
        end
      end

      context "when user is not an admin" do
        let(:current_user) { create(:user, admin: false) }

        before { sign_in(current_user) }

        before { get new_user_path }

        it "is expected to redirect to root path with status found" do
          expect(response).to redirect_to(root_path)

          expect(response).to have_http_status(:found)

          expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
        end
      end
    end

    context "when user is not logged in" do
      before { get new_user_path }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)
      end
    end
  end

  # describe "#edit" do
  #   context "when user is logged in" do
  #     context "when user is an admin" do
  #       context "when admin editing himself" do
  #         let(:current_user) { create(:user, admin: true) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { get edit_user_path(current_user) }
  #
  #         it "is expected to render template edit with status ok" do
  #           expect(response).to render_template(:edit)
  #
  #           expect(response).to have_http_status(:ok)
  #
  #           expect(assigns(:user)).to eq(current_user)
  #         end
  #       end
  #
  #       context "when admin editing another admin" do
  #         let(:current_user) { create(:user, admin: true) }
  #
  #         let!(:another_admin) { create(:user, admin: true) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { get edit_user_path(another_admin) }
  #
  #         it "is expected to render template edit with status ok" do
  #           expect(response).to render_template(:edit)
  #
  #           expect(response).to have_http_status(:ok)
  #
  #           expect(assigns(:user)).to eq(another_admin)
  #         end
  #       end
  #
  #       context "when admin editing user" do
  #         let(:current_user) { create(:user, admin: true) }
  #
  #         let!(:another_user) { create(:user, admin: false) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { get edit_user_path(another_user) }
  #
  #         it "is expected to render template edit with status ok" do
  #           expect(response).to render_template(:edit)
  #
  #           expect(response).to have_http_status(:ok)
  #
  #           expect(assigns(:user)).to eq(another_user)
  #         end
  #       end
  #     end
  #
  #     context "when user is not an admin" do
  #       context "when user editing himself" do
  #         let(:current_user) { create(:user, admin: false) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { get edit_user_path(current_user) }
  #
  #         it "is expected to render template edit with status ok" do
  #           expect(response).to render_template(:edit)
  #
  #           expect(response).to have_http_status(:ok)
  #
  #           expect(assigns(:user)).to eq(current_user)
  #         end
  #       end
  #
  #       context "when user editing another user" do
  #         let(:current_user) { create(:user, admin: false) }
  #
  #         let(:another_user) { create(:user, admin: false) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { get edit_user_path(another_user) }
  #
  #         it "is expected to redirect to root path with status found" do
  #           expect(response).to redirect_to(root_path)
  #
  #           expect(response).to have_http_status(:found)
  #
  #           expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
  #         end
  #       end
  #
  #       context "when user editing admin" do
  #         let(:current_user) { create(:user, admin: false) }
  #
  #         let(:admin) { create(:user, admin: true) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { get edit_user_path(admin) }
  #
  #         it "is expected to redirect to root path with status found" do
  #           expect(response).to redirect_to(root_path)
  #
  #           expect(response).to have_http_status(:found)
  #
  #           expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
  #         end
  #       end
  #     end
  #   end
  #
  #   context "when user is not logged in" do
  #     let!(:user) { create(:user) }
  #
  #     before { get edit_user_path(user) }
  #
  #     it "is expected to redirect to new user session path with status found" do
  #       expect(response).to redirect_to(new_user_session_path)
  #
  #       expect(response).to have_http_status(:found)
  #     end
  #   end
  # end
  #
  # describe "#create" do
  #   context "when user is logged in" do
  #     context "when user is an admin" do
  #       let(:current_user) { create(:user, admin: true) }
  #
  #       before { sign_in(current_user) }
  #
  #       let(:email) { Faker::Internet.unique.email }
  #
  #       let(:password) { Faker::Internet.password }
  #
  #       let(:name) { Faker::Name.unique.name }
  #
  #       before do
  #         expect do
  #           post users_path,
  #             params: {
  #               user: {
  #                 email: email,
  #                 name: name,
  #                 password: password,
  #                 password_confirmation: password,
  #                 admin: true
  #               }
  #             }
  #         end.to change(User, :count).by(1)
  #       end
  #
  #       it "is expected to create a new user with status found" do
  #         expect(response).to redirect_to(user_path(assigns(:user)))
  #
  #         expect(response).to have_http_status(:found)
  #
  #         expect(request.flash[:success]).to eq("#{name} is now part of the team. Be sure to add them as a project watcher.")
  #
  #         expect(assigns(:user).email).to eq(email)
  #
  #         expect(assigns(:user).name).to eq(name)
  #
  #         expect(assigns(:user).admin).to eq(true)
  #       end
  #     end
  #
  #     context "when user is not an admin" do
  #       let(:current_user) { create(:user, admin: false) }
  #
  #       before { sign_in(current_user) }
  #
  #       let(:email) { Faker::Internet.unique.email }
  #
  #       let(:password) { Faker::Internet.password }
  #
  #       let(:name) { Faker::Name.unique.name }
  #
  #       before do
  #         expect do
  #           post users_path,
  #             params: {
  #               user: {
  #                 email: email,
  #                 name: name,
  #                 password: password,
  #                 password_confirmation: password,
  #                 admin: true
  #               }
  #             }
  #         end.not_to change(User, :count)
  #       end
  #
  #       it "is expected to redirect to root path with status found" do
  #         expect(response).to redirect_to(root_path)
  #
  #         expect(response).to have_http_status(:found)
  #
  #         expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
  #       end
  #     end
  #   end
  #
  #   context "when user is not logged in" do
  #     let(:email) { Faker::Internet.unique.email }
  #
  #     let(:password) { Faker::Internet.password }
  #
  #     let(:name) { Faker::Name.unique.name }
  #
  #     before do
  #       expect do
  #         post users_path,
  #           params: {
  #             user: {
  #               email: email,
  #               name: name,
  #               password: password,
  #               password_confirmation: password,
  #               admin: true
  #             }
  #           }
  #       end.not_to change(User, :count)
  #     end
  #
  #     it "is expected to redirect to new user session path with status found" do
  #       expect(response).to redirect_to(new_user_session_path)
  #
  #       expect(response).to have_http_status(:found)
  #     end
  #   end
  # end
  #
  # describe "#update" do
  #   context "when user is logged in" do
  #     context "when user is an admin" do
  #       context "when admin updating himself" do
  #         let(:current_user) { create(:user, admin: true) }
  #
  #         before { sign_in(current_user) }
  #
  #         before do
  #           patch user_path(current_user),
  #             params: {
  #               user: {
  #                 name: "New Name",
  #                 email: ""
  #               }
  #             }
  #         end
  #
  #
  #       end
  #
  #       context "when admin updating another admin" do
  #
  #       end
  #
  #       context "when admin updating user" do
  #
  #       end
  #     end
  #   end
  #
  #   context "when user is not logged in" do
  #     let(:user) { create(:user) }
  #
  #     before do
  #       patch user_path(user),
  #         params: {
  #           user: {
  #             name: "New Name",
  #             email: "me@example.com"
  #           }
  #         }
  #     end
  #
  #     it "is expected to redirect to new user session path with status found" do
  #       expect(response).to redirect_to(new_user_session_path)
  #
  #       expect(response).to have_http_status(:found)
  #     end
  #   end
  # end

  describe "#destroy" do
    context "when user is logged in" do
      context "when user is an admin" do
        context "when admin removes himself" do
          let(:current_user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          before { expect(UserDestroy).not_to receive(:new) }

          before { expect { delete user_path(current_user) }.not_to change(User, :count) }

          it "is expected to redirect to root path with status found" do
            expect(response).to redirect_to(root_path)

            expect(response).to have_http_status(:found)

            expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
          end
        end

  #       context "when admin removes another admin" do
  #         let(:current_user) { create(:user, admin: true) }
  #
  #         let!(:admin) { create(:user, admin: true) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { expect(UserDestroy).to receive(:new).with(admin).and_call_original }
  #
  #         before { expect { delete user_path(admin) }.to change(User, :count).by(-1) }
  #
  #         it "is expected to redirect to users path with status found" do
  #           expect(response).to redirect_to(users_path)
  #
  #           expect(response).to have_http_status(:found)
  #
  #           expect(request.flash[:success]).to eq(I18n.t("controllers.users.flash.destroy.success", name: admin.name))
  #         end
  #       end
  #
  #       context "when admin removes user" do
  #         let(:current_user) { create(:user, admin: true) }
  #
  #         let!(:user) { create(:user, admin: false) }
  #
  #         before { sign_in(current_user) }
  #
  #         before { expect(UserDestroy).to receive(:new).with(user).and_call_original }
  #
  #         before { expect { delete user_path(user) }.to change(User, :count).by(-1) }
  #
  #         it "is expected to redirect to users path with status found" do
  #           expect(response).to redirect_to(users_path)
  #
  #           expect(response).to have_http_status(:found)
  #
  #           expect(request.flash[:success]).to eq(I18n.t("controllers.users.flash.destroy.success", name: user.name))
  #         end
  #       end
      end

      context "when user is not an admin" do
        context "when user is removing himself" do
          let(:current_user) { create(:user, admin: false) }

          before { sign_in(current_user) }

          before { expect(UserDestroy).not_to receive(:new) }

          before { expect { delete user_path(current_user) }.not_to change(User, :count) }

          it "is expected to redirect to users path with status found" do
            expect(response).to redirect_to(root_path)

            expect(response).to have_http_status(:found)

            expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
          end
        end

        context "when user is removing another user" do
          let(:current_user) { create(:user, admin: false) }

          let!(:user) { create(:user, admin: false) }

          before { sign_in(current_user) }

          before { expect(UserDestroy).not_to receive(:new) }

          before { expect { delete user_path(user) }.not_to change(User, :count) }

          it "is expected to redirect to users path with status found" do
            expect(response).to redirect_to(root_path)

            expect(response).to have_http_status(:found)

            expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
          end
        end

        context "when user is removing admin" do
          let(:current_user) { create(:user, admin: false) }

          let!(:user) { create(:user, admin: true) }

          before { sign_in(current_user) }

          before { expect(UserDestroy).not_to receive(:new) }

          before { expect { delete user_path(user) }.not_to change(User, :count) }

          it "is expected to redirect to users path with status found" do
            expect(response).to redirect_to(root_path)

            expect(response).to have_http_status(:found)

            expect(request.flash[:alert]).to eq("You are not authorized to perform this action.")
          end
        end
      end
    end

    context "when user is not logged in" do
      let(:user) { create(:user) }

      before { delete user_path(user) }

      it "is expected to redirect to new user session path with status found" do
        expect(response).to redirect_to(new_user_session_path)

        expect(response).to have_http_status(:found)
      end
    end
  end
end
