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

  describe ".find_or_create_from_openid_connect" do
    let(:auth) do
      Hashie::Mash.new(uid: "subject-1", info: {
        email: "oidc@example.com", email_verified: true, name: "OIDC User"
      })
    end

    before { Errbit::Config.oidc_issuer = "https://issuer.example.com" }
    after do
      Errbit::Config.oidc_issuer = nil
      Errbit::Config.oidc_authorized_domains = nil
    end

    it "associates a verified email with an existing user" do
      user = create(:user, email: "oidc@example.com")

      expect(User.find_or_create_from_openid_connect(auth)).to eq(user)
      expect(user.reload.oidc_uid).to eq("subject-1")
    end

    it "normalizes email casing when associating an existing user" do
      user = create(:user, email: "oidc@example.com")
      auth.info.email = "OIDC@EXAMPLE.COM"

      expect(User.find_or_create_from_openid_connect(auth)).to eq(user)
    end

    it "provisions only when enabled" do
      expect(User.find_or_create_from_openid_connect(auth)).to be_nil
      user = User.find_or_create_from_openid_connect(auth, auto_provision: true)

      expect(user).to be_persisted
      expect(user.name).to eq("OIDC User")
    end

    it "rejects an unverified email" do
      auth.info.email_verified = false

      expect(User.find_or_create_from_openid_connect(auth, auto_provision: true)).to be_nil
    end

    it "uses the email as a name fallback" do
      auth.info.name = nil

      user = User.find_or_create_from_openid_connect(auth, auto_provision: true)

      expect(user.name).to eq("oidc@example.com")
    end

    it "allows provisioning inside authorized domains case-insensitively" do
      Errbit::Config.oidc_authorized_domains = "TRUSTED.EXAMPLE"
      auth.info.email = "OIDC@TRUSTED.EXAMPLE"

      expect(User.find_or_create_from_openid_connect(auth, auto_provision: true)).to be_persisted
    end

    it "rejects provisioning outside the authorized domains" do
      Errbit::Config.oidc_authorized_domains = "trusted.example"

      expect(User.find_or_create_from_openid_connect(auth, auto_provision: true)).to be_nil
    end

    it "does not replace an existing OIDC identity during email association" do
      user = create(:user, email: "oidc@example.com", oidc_issuer: Errbit::Config.oidc_issuer, oidc_uid: "subject-A")
      auth.uid = "subject-B"

      expect(User.find_or_create_from_openid_connect(auth)).to be_nil
      expect(user.reload.oidc_uid).to eq("subject-A")
    end

    it "associates an email with an atomic empty-identity update" do
      user = create(:user, email: "oidc@example.com")
      criteria = instance_double(Mongoid::Criteria)
      expect(criteria).to receive(:find_one_and_update).with(
        {"$set" => {
          oidc_issuer: Errbit::Config.oidc_issuer,
          oidc_uid: "subject-1"
        }},
        return_document: :after
      ).and_return(user)
      allow(User).to receive(:where).with(
        oidc_issuer: Errbit::Config.oidc_issuer, oidc_uid: "subject-1"
      ).and_return([])
      allow(User).to receive(:where).with(
        email: "oidc@example.com", oidc_issuer: nil, oidc_uid: nil
      ).and_return(criteria)

      expect(User.find_or_create_from_openid_connect(auth)).to eq(user)
    end

    it "reuses an existing identity instead of creating a duplicate" do
      user = User.find_or_create_from_openid_connect(auth, auto_provision: true)

      expect(User.find_or_create_from_openid_connect(auth, auto_provision: true)).to eq(user)
      expect(User.where(oidc_issuer: Errbit::Config.oidc_issuer, oidc_uid: "subject-1").count).to eq(1)
    end

    it "reloads an identity after a duplicate-key provisioning error" do
      competing_user = build(:user, oidc_issuer: Errbit::Config.oidc_issuer, oidc_uid: "subject-1")
      operation_failure = Mongo::Error::OperationFailure.new("duplicate")
      allow(operation_failure).to receive(:code).and_return(11_000)
      allow(User).to receive(:create).and_raise(operation_failure)
      criteria = instance_double(Mongoid::Criteria)
      allow(criteria).to receive(:find_one_and_update).and_return(nil)
      allow(User).to receive(:where).with(
        email: "oidc@example.com", oidc_issuer: nil, oidc_uid: nil
      ).and_return(criteria)
      allow(User).to receive(:where).with(email: "oidc@example.com").and_return([])
      allow(User).to receive(:where).with(
        oidc_issuer: Errbit::Config.oidc_issuer, oidc_uid: "subject-1"
      ).and_return([], [], [competing_user])

      expect(User.find_or_create_from_openid_connect(auth, auto_provision: true)).to eq(competing_user)
    end
  end
end
