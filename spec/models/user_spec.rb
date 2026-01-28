# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  context "validations" do
    it "require that a name is present" do
      user = build(:user, name: nil)

      expect(user.valid?).to eq(false)

      expect(user.errors[:name]).to eq(["can't be blank"])
    end

    it "requires password without github login" do
      user = build(:user, password: nil)

      expect(user.valid?).to eq(false)

      expect(user.errors[:password]).to eq(["can't be blank"])
    end

    it "doesn't require password with github login" do
      user = build(:user, password: nil, github_login: "biow0lf")

      expect(user.valid?).to eq(true)
    end

    it "requires uniq github login" do
      user_1 = create(:user, github_login: "biow0lf")
      expect(user_1.valid?).to eq(true)

      user_2 = build(:user, github_login: "biow0lf")
      user_2.save
      expect(user_2.valid?).to eq(false)

      expect(user_2.errors[:github_login]).to eq(["has already been taken"])
    end

    it "allows blank / null github_login" do
      user_1 = create(:user, github_login: " ")
      expect(user_1.valid?).to eq(true)

      user_2 = build(:user, github_login: " ")
      user_2.save

      expect(user_2.valid?).to eq(true)
    end

    it "disables validations when reset password" do
      user = build(:user, email: "")
      user.save(validate: false)

      expect(user.reset_password("Password123", "Password123")).to eq(true)
    end

    it "should require a password with minimum of 8 characters" do
      user = build(:user)

      user.reset_password("1234567", "1234578")

      expect(user.errors[:password]).to eq(["is too short (minimum is 8 characters)"])
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

  describe "#attributes_for_super_diff" do
    subject { create(:user) }

    it { expect(subject.attributes_for_super_diff).to eq(id: subject.id.to_s, name: subject.name) }
  end
end
