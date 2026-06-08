# frozen_string_literal: true

require "rails_helper"

RSpec.describe WatchersController, type: :controller do
  let(:user) { create(:errbit_user) }

  before { sign_in user }

  describe "#create" do
    let(:app) { create(:errbit_app) }

    context "when create succeeds" do
      before { post :create, params: {app_id: app.id} }

      it "adds the current user as an Errbit::Watcher on the app" do
        expect(app.watchers.reload.first.user).to eq(user)
      end

      it "redirects to the app page" do
        expect(response).to redirect_to(app_path(app))
      end
    end
  end

  describe "#destroy" do
    let(:app) do
      a = create(:errbit_app)
      create(:errbit_user_watcher, app: a, user: user)
      a
    end

    context "when destroy succeeds" do
      let!(:watcher) { app.watchers.find_by(errbit_user_id: user.id) }

      before { delete :destroy, params: {app_id: app.id} }

      it "removes the watcher" do
        expect(Errbit::Watcher.where(id: watcher.id)).to be_empty
        expect(app.watchers.reload).to be_empty
      end

      it "redirects to the app page" do
        expect(response).to redirect_to(app_path(app))
      end
    end
  end
end
