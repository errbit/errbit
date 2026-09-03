# frozen_string_literal: true

require "rails_helper"

RSpec.describe WatchersController, type: :controller do
  let(:user) { create(:errbit_user) }

  before { sign_in user }

  describe "#create" do
    let(:app) { create(:errbit_app) }

    context "successful watcher create" do
      before do
        post :create, params: {app_id: app.id}

        app.reload
      end

      it "should be watching" do
        app.reload

        expect(app.watchers.first.user).to eq(user)
      end

      it "should redirect to app page" do
        expect(response).to redirect_to(app_path(app))
      end
    end
  end

  describe "#destroy" do
    let(:app) do
      a = create(:errbit_app)
      create(:errbit_watcher, app: a, user: user, email: nil, watcher_type: "user")
      a
    end

    context "successful watcher deletion" do
      let(:watcher) { app.watchers.first }

      before do
        delete :destroy, params: {app_id: app.id}

        app.reload
      end

      it "should delete the watcher" do
        expect(app.watchers.detect { |w| w.id.to_s == watcher.id }).to eq(nil)
      end

      it "should redirect to app page" do
        expect(response).to redirect_to(app_path(app))
      end
    end
  end
end
