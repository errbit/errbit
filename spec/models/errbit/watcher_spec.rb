# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Watcher, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_watchers table" do
    expect(described_class.table_name).to eq("errbit_watchers")
  end

  context "validations" do
    it "requires an email address or an associated user" do
      watcher = build(:errbit_watcher, email: nil, user: nil)
      expect(watcher.valid?).to eq(false)
      expect(watcher.errors[:base]).to include("You must specify either a user or an email address")

      watcher.email = "watcher@example.com"
      expect(watcher.valid?).to eq(true)

      watcher.email = nil
      expect(watcher.valid?).to eq(false)

      watcher.user = create(:errbit_user)
      watcher.watcher_type = "user"
      expect(watcher.valid?).to eq(true)
    end

    it "requires an associated app" do
      watcher = build(:errbit_watcher, app: nil)

      expect(watcher.valid?).to eq(false)
      expect(watcher.errors[:app]).to include("must exist")
    end
  end

  describe "#address" do
    it "returns the user's email address if there is a user" do
      user = create(:errbit_user, email: "foo@bar.com")
      watcher = create(:errbit_user_watcher, user: user)

      expect(watcher.address).to eq("foo@bar.com")
    end

    it "returns the email if there is no user" do
      watcher = create(:errbit_watcher, email: "widgets@acme.com")

      expect(watcher.address).to eq("widgets@acme.com")
    end
  end

  describe "#label" do
    it "is the user's name when a user is set" do
      user = create(:errbit_user, name: "Alice")
      watcher = create(:errbit_user_watcher, user: user)

      expect(watcher.label).to eq("Alice")
    end

    it "is the email when no user is set" do
      watcher = create(:errbit_watcher, email: "bob@example.com")

      expect(watcher.label).to eq("bob@example.com")
    end
  end

  describe "#email_choosen" do
    context "with email defined" do
      it "returns blank" do
        expect(described_class.new(email: "foo").email_choosen).to eq("")
      end
    end

    context "without email defined" do
      it "returns chosen" do
        expect(described_class.new(email: "").email_choosen).to eq("chosen")
      end
    end
  end

  describe "before_validation :clear_unused_watcher_type" do
    it "clears email when watcher_type is user" do
      user = create(:errbit_user)
      watcher = build(:errbit_watcher, user: user, email: "stale@example.com", watcher_type: "user")

      watcher.valid?

      expect(watcher.email).to be_nil
    end

    it "clears user when watcher_type is email" do
      user = create(:errbit_user)
      watcher = build(:errbit_watcher, user: user, email: "kept@example.com", watcher_type: "email")

      watcher.valid?

      expect(watcher.user).to be_nil
      expect(watcher.errbit_user_id).to be_nil
    end
  end

  describe "Errbit::App#watched_by?" do
    let(:app) { create(:errbit_app) }
    let(:user) { create(:errbit_user) }

    it "is true when the user has a watcher on the app" do
      create(:errbit_user_watcher, app: app, user: user)

      expect(app.watched_by?(user)).to eq(true)
    end

    it "is false when the user has no watcher on the app" do
      expect(app.watched_by?(user)).to eq(false)
    end
  end
end
