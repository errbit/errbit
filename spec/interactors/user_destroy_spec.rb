# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDestroy do
  describe "#destroy" do
    let!(:app) { create(:app) }
    let!(:user) { create(:errbit_user) }
    let!(:user_watcher) { create(:user_watcher, app: app, user: user) }

    it "is expected to delete user" do
      expect do
        described_class.new(user).destroy
      end.to change(Errbit::User, :count).from(1).to(0)
    end

    it "is expected to delete watcher" do
      expect do
        described_class.new(user).destroy
      end.to change {
        app.reload.watchers.where(user: user).count
      }.from(1).to(0)
    end
  end
end
