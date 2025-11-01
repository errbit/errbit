# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDestroy do
  let(:app) do
    Fabricate(
      :app,
      watchers: [
        Fabricate.build(:user_watcher, user: user)
      ]
    )
  end

  describe "#destroy" do
    let!(:user) { create(:errbit_user) }

    it "is expected to delete user" do
      expect do
        described_class.new(user).destroy
      end.to change(Errbit::User, :count)
    end

    it "is expected to delete watcher" do
      expect do
        described_class.new(user).destroy
      end.to change {
        app.reload.watchers.where(user_id: user.id).count
      }.from(1).to(0)
    end
  end
end
