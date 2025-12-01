# frozen_string_literal: true

require "rails_helper"

RSpec.describe Watcher, type: :model do
  context "validations" do
    it "requires an email address or an associated user" do
      watcher = build(:watcher, email: nil, user: nil)
      expect(watcher.valid?).to eq(false)
      expect(watcher.errors[:base]).to include("You must specify either a user or an email address")

      watcher.email = "watcher@example.com"
      expect(watcher.valid?).to eq(true)

      watcher.email = nil
      expect(watcher.valid?).to eq(false)

      watcher.user = create(:user)
      watcher.watcher_type = "user"
      expect(watcher.valid?).to eq(true)
    end
  end

  context "address" do
    it "returns the user's email address if there is a user" do
      user = create(:user, email: "foo@bar.com")
      watcher = create(:user_watcher, user: user)
      expect(watcher.address).to eq("foo@bar.com")
    end

    it "returns the email if there is no user" do
      watcher = create(:watcher, email: "widgets@acme.com")
      expect(watcher.address).to eq("widgets@acme.com")
    end
  end

  describe "#email_choosen" do
    context "with email define" do
      it "return blank" do
        expect(described_class.new(email: "foo").email_choosen).to eq("")
      end
    end

    context "without email define" do
      it "return choosen" do
        expect(described_class.new(email: "").email_choosen).to eq("chosen")
      end
    end
  end
end
