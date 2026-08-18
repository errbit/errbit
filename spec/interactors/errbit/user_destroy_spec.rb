# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::UserDestroy do
  it "destroys the user and dependent watchers" do
    user = create(:errbit_user)
    app = create(:errbit_app)
    create(:errbit_watcher, app: app, user: user, email: nil, watcher_type: "user")

    expect { described_class.new(user).destroy }
      .to change(Errbit::User, :count).by(-1)

    expect(Errbit::Watcher.where(errbit_user_id: user.id)).to be_empty
  end
end
