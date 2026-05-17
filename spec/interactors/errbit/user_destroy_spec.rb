# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::UserDestroy do
  describe "#destroy" do
    let!(:app) { create(:errbit_app) }
    let!(:user) { create(:errbit_user) }
    let!(:user_watcher) { create(:errbit_user_watcher, app: app, user: user) }

    it "destroys the user" do
      expect { described_class.new(user).destroy }.to change(Errbit::User, :count).by(-1)
    end

    it "destroys watchers belonging to the user via dependent: :destroy" do
      expect { described_class.new(user).destroy }
        .to change { Errbit::Watcher.where(errbit_user_id: user.id).count }
        .from(1).to(0)
    end
  end
end
