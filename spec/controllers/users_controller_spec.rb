# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :controller do
  it_requires_authentication

  it_requires_admin_privileges for: {
    index: :get,
    show: :get,
    new: :get,
    create: :post,
    destroy: :delete
  }

  let(:admin) { Fabricate(:admin) }

  let(:user) { Fabricate(:user) }

  let(:other_user) { Fabricate(:user) }

  context "Signed in as a regular user" do
    before do
      sign_in user
    end

    it "should set a time zone" do
      expect(Time.zone.to_s).to match(user.time_zone)
    end

    context "PUT /users/:other_id" do
      it "redirects to the home page" do
        put :update, params: {id: other_user.id}
        expect(response).to redirect_to(root_path)
      end
    end

    context "PUT /users/:my_id/id" do
      context "when the update is successful" do
        it "sets a message to display" do
          put :update, params: {id: user.to_param, user: {name: "Kermit"}}
          expect(request.flash[:success]).to include("updated")
        end

        it "redirects to the user's page" do
          put :update, params: {id: user.to_param, user: {name: "Kermit"}}
          expect(response).to redirect_to(user_path(user))
        end

        it "should not be able to become an admin" do
          expect do
            put :update, params: {id: user.to_param, user: {admin: true}}
          end.not_to change {
            user.reload.admin
          }.from(false)
        end

        it "should be able to set per_page option" do
          put :update, params: {id: user.to_param, user: {per_page: 555}}
          expect(user.reload.per_page).to eq 555
        end

        it "should be able to set time_zone option" do
          put :update, params: {id: user.to_param, user: {time_zone: "Warsaw"}}
          expect(user.reload.time_zone).to eq "Warsaw"
        end

        it "should be able to not set github_login option" do
          put :update, params: {id: user.to_param, user: {github_login: " "}}
          expect(user.reload.github_login).to eq nil
        end

        it "should be able to set github_login option" do
          put :update, params: {id: user.to_param, user: {github_login: "awesome_name"}}
          expect(user.reload.github_login).to eq "awesome_name"
        end
      end

      context "when the update is unsuccessful" do
        it "renders the edit page" do
          put :update, params: {id: user.to_param, user: {name: nil}}
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  context "Signed in as an admin" do
    before do
      sign_in admin
    end


    context "POST /users" do
      context "when the create is successful" do
        let(:attrs) { {user: Fabricate.to_params(:user)} }

        it "sets a message to display" do
          post :create, params: {**attrs}
          expect(request.flash[:success]).to include("part of the team")
        end

        it "redirects to the user's page" do
          post :create, params: {**attrs}
          expect(response).to redirect_to(user_path(controller.user))
        end

        it "should be able to create admin" do
          attrs[:user][:admin] = true
          post :create, params: {**attrs}
          expect(response).to be_redirect
          expect(User.find(controller.user.to_param).admin).to be(true)
        end

        it "should has auth token" do
          post :create, params: {**attrs}
          expect(User.last.authentication_token).not_to be_blank
        end
      end

      context "when the create is unsuccessful" do
        let(:user) do
          Struct.new(:admin, :attributes).new(true, {})
        end

        before do
          expect(User).to receive(:new).and_return(user)
          expect(user).to receive(:save).and_return(false)
        end

        it "renders the new page" do
          post :create, params: {user: {username: "foo"}}
          expect(response).to render_template(:new)
        end
      end
    end

    context "PUT /users/:id" do
      context "when the update is successful" do
        before do
          put :update, params: {id: user.to_param, user: user_params}
        end

        context "with normal params" do
          let(:user_params) { {name: "Kermit"} }

          it "sets a message to display" do
            expect(request.flash[:success]).to eq I18n.t("controllers.users.flash.update.success", name: user.reload.name)
            expect(response).to redirect_to(user_path(user))
          end
        end
      end

      context "when the update is unsuccessful" do
        it "renders the edit page" do
          put :update, params: {id: user.to_param, user: {name: nil}}
          expect(response).to render_template(:edit)
        end
      end
    end
  end
end
