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
