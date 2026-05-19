# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  context "validations" do
    it "require that a name is present" do
      user = build(:user, name: nil)

      expect(user.valid?).to eq(false)

      expect(user.errors[:name]).to eq(["can't be blank"])
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
  end

  describe "#attributes_for_super_diff" do
    subject { create(:user) }

    it { expect(subject.attributes_for_super_diff).to eq(id: subject.id.to_s, name: subject.name) }
  end
end
