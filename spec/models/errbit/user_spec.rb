# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::User, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_users table" do
    expect(described_class.table_name).to eq("errbit_users")
  end

  describe "PER_PAGE" do
    it { expect(described_class::PER_PAGE).to eq(30) }
  end

  context "validations" do
    it "requires that a name is present" do
      user = build(:errbit_user, name: nil)

      expect(user.valid?).to eq(false)
      expect(user.errors[:name]).to eq(["can't be blank"])
    end

    it "requires password without github login" do
      user = build(:errbit_user, password: nil)

      expect(user.valid?).to eq(false)
      expect(user.errors[:password]).to eq(["can't be blank"])
    end

    it "doesn't require password with github login" do
      user = build(:errbit_user, password: nil, github_login: "biow0lf")

      expect(user.valid?).to eq(true)
    end

    it "requires uniq github login" do
      user_1 = create(:errbit_user, github_login: "biow0lf")
      expect(user_1.valid?).to eq(true)

      user_2 = build(:errbit_user, github_login: "biow0lf")
      user_2.save
      expect(user_2.valid?).to eq(false)

      expect(user_2.errors[:github_login]).to eq(["has already been taken"])
    end

    it "allows blank / null github_login" do
      user_1 = create(:errbit_user, github_login: " ")
      expect(user_1.valid?).to eq(true)

      user_2 = build(:errbit_user, github_login: " ")
      user_2.save

      expect(user_2.valid?).to eq(true)
    end

    it "disables validations when reset password" do
      user = build(:errbit_user, email: "")
      user.save(validate: false)

      expect(user.reset_password("Password123", "Password123")).to eq(true)
    end

    it "should require a password with minimum of 8 characters" do
      user = build(:errbit_user)

      user.reset_password("1234567", "1234578")

      expect(user.errors[:password]).to eq(["is too short (minimum is 8 characters)"])
    end
  end

  describe "#per_page" do
    context "when not set" do
      it "falls back to PER_PAGE constant" do
        user = build(:errbit_user)
        user[:per_page] = nil

        expect(user.per_page).to eq(30)
      end
    end

    context "when set" do
      it "returns the stored value" do
        user = build(:errbit_user)
        user[:per_page] = 50

        expect(user.per_page).to eq(50)
      end
    end
  end

  describe "#github_login=" do
    it "normalizes blank strings to nil" do
      user = build(:errbit_user, github_login: "   ")

      expect(user.github_login).to be_nil
    end

    it "stores non-blank strings" do
      user = build(:errbit_user, github_login: "biow0lf")

      expect(user.github_login).to eq("biow0lf")
    end
  end

  describe "#github_account?" do
    it "is true when login and oauth token are present" do
      user = build(:errbit_user, github_login: "biow0lf", github_oauth_token: "token")

      expect(user.github_account?).to eq(true)
    end

    it "is false when oauth token is blank" do
      user = build(:errbit_user, github_login: "biow0lf")

      expect(user.github_account?).to eq(false)
    end
  end

  describe "#google_account?" do
    it "is true when google_uid is present" do
      user = build(:errbit_user, google_uid: "12345")

      expect(user.google_account?).to eq(true)
    end

    it "is false when google_uid is blank" do
      user = build(:errbit_user)

      expect(user.google_account?).to eq(false)
    end
  end

  describe ".valid_google_domain?" do
    context "without an authorized domains list" do
      before { allow(Errbit::Config).to receive(:google_authorized_domains).and_return("") }

      it "accepts any email" do
        expect(described_class.valid_google_domain?("anyone@example.com")).to eq(true)
      end
    end

    context "with an authorized domains list" do
      before { allow(Errbit::Config).to receive(:google_authorized_domains).and_return("example.com,foo.org") }

      it "accepts a matching domain" do
        expect(described_class.valid_google_domain?("user@example.com")).to eq(true)
      end

      it "rejects a non-matching domain" do
        expect(described_class.valid_google_domain?("user@other.com")).to eq(false)
      end

      it "rejects an unparseable email" do
        expect(described_class.valid_google_domain?("not-an-email")).to eq(false)
      end
    end
  end

  describe ".create_from_google_oauth2" do
    let(:access_token) do
      {
        uid: "uid-123",
        info: {email: "newuser@example.com", name: "New User"}
      }
    end

    it "creates a new user when none exists" do
      expect {
        described_class.create_from_google_oauth2(access_token)
      }.to change(described_class, :count).by(1)
    end

    it "returns the existing user when email matches" do
      existing = create(:errbit_user, email: "newuser@example.com")

      result = described_class.create_from_google_oauth2(access_token)

      expect(result).to eq(existing)
    end
  end

  describe ".token_authentication_key" do
    it "returns :auth_token" do
      expect(described_class.token_authentication_key).to eq(:auth_token)
    end
  end

  describe "#ensure_authentication_token" do
    it "generates a token before save" do
      user = build(:errbit_user)

      user.save!

      expect(user.authentication_token).to be_present
    end

    it "does not overwrite an existing token" do
      user = create(:errbit_user)
      token = user.authentication_token

      user.update!(name: "Renamed")

      expect(user.authentication_token).to eq(token)
    end
  end

  describe "#attributes_for_super_diff" do
    subject { create(:errbit_user) }

    it { expect(subject.attributes_for_super_diff).to eq(id: subject.id, name: subject.name) }
  end
end
