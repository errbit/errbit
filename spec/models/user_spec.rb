# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  context "validations" do
    it "require that a name is present" do
      user = Fabricate.build(:user, name: nil)

      expect(user.valid?).to eq(false)

      expect(user.errors[:name]).to eq(["can't be blank"])
    end

    it "requires password without github login" do
      user = Fabricate.build(:user, password: nil)

      expect(user.valid?).to eq(false)

      expect(user.errors[:password]).to eq(["can't be blank"])
    end

    it "doesn't require password with github login" do
      user = Fabricate.build(:user, password: nil, github_login: "nashby")

      expect(user.valid?).to eq(true)
    end

    it "requires uniq github login" do
      user1 = Fabricate(:user, github_login: "nashby")
      expect(user1.valid?).to eq(true)

      user2 = Fabricate.build(:user, github_login: "nashby")
      user2.save
      expect(user2.valid?).to eq(false)

      expect(user2.errors[:github_login]).to eq(["has already been taken"])
    end

    it "allows blank / null github_login" do
      user1 = Fabricate(:user, github_login: " ")
      expect(user1.valid?).to eq(true)

      user2 = Fabricate.build(:user, github_login: " ")
      user2.save

      expect(user2.valid?).to eq(true)
    end

    it "disables validations when reset password" do
      user = Fabricate.build(:user, email: "")
      user.save(validate: false)
      expect(user.reset_password("Password123", "Password123")).to be_truthy
    end

    it "should require a password with minimum of 6 characters" do
      user = Fabricate.build(:user)
      user.reset_password("12345", "12345")
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)", "is too short (minimum is 6 characters)")
    end
  end

  context "First user" do
    it "should be created this admin access via db:seed" do
      expect do
        allow($stdout).to receive(:puts).and_return(true)
        require Rails.root.join("db/seeds.rb")
      end.to change {
        User.where(admin: true).count
      }.by(1)
    end
  end
end
