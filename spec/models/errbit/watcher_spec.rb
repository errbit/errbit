# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Watcher, type: :model do
  it "can watch by raw email address" do
    watcher = create(:errbit_watcher, email: "alerts@example.com")

    expect(watcher.address).to eq("alerts@example.com")
    expect(watcher.label).to eq("alerts@example.com")
  end

  it "can watch by user" do
    user = create(:errbit_user, email: "user@example.com", name: "User Watcher")
    watcher = create(:errbit_watcher, watcher_type: "user", user: user, email: "ignored@example.com")

    expect(watcher.email).to be_nil
    expect(watcher.address).to eq("user@example.com")
    expect(watcher.label).to eq("User Watcher")
  end

  it "requires either a user or email" do
    watcher = build(:errbit_watcher, email: nil, user: nil)

    expect(watcher).not_to be_valid
    expect(watcher.errors[:base]).to include("You must specify either a user or an email address")
  end
end
