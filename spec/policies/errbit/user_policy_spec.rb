# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::UserPolicy do
  subject { described_class.new(user, record) }

  it do
    expect(described_class::FIELDS)
      .to eq([:name, :username, :email, :password, :github_login, :per_page, :time_zone, :password, :password_confirmation])
  end

  describe "#initialize" do
    context "when user not present" do
      let(:record) { create(:errbit_user) }

      let(:user) { nil }

      it { expect { subject }.to raise_error(Pundit::NotAuthorizedError) }
    end
  end

  describe "#index" do
    let(:record) { create(:errbit_user, admin: false) }

    context "when user is an admin" do
      let(:user) { create(:errbit_user, admin: true) }

      it { is_expected.to forbid_action(:index) }
    end

    context "when user is not an admin" do
      let(:user) { create(:errbit_user, admin: false) }

      it { is_expected.to forbid_action(:index) }
    end
  end

  # describe "#show?" do
  #   context "when user is an admin" do
  #     let(:user) { create(:user, admin: true) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to permit_action(:show) }
  #   end
  #
  #   context "when user is not an admin" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to forbid_action(:show) }
  #   end
  #
  #   context "when user is an owner" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { user }
  #
  #     it { is_expected.to permit_action(:show) }
  #   end
  # end

  describe "#create?" do
    context "when user is an admin" do
      let(:user) { create(:errbit_user, admin: true) }

      let(:record) { Errbit::User.new }

      it { is_expected.to permit_action(:create) }
    end

    context "when user is not an admin" do
      let(:user) { create(:errbit_user, admin: false) }

      let(:record) { Errbit::User.new }

      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "#new?" do
    context "when user is an admin" do
      let(:user) { create(:errbit_user, admin: true) }

      let(:record) { Errbit::User.new }

      it { is_expected.to permit_action(:new) }
    end

    context "when user is not an admin" do
      let(:user) { create(:errbit_user, admin: false) }

      let(:record) { Errbit::User.new }

      it { is_expected.to forbid_action(:new) }
    end
  end

  # describe "#update?" do
  #   context "when user is an admin" do
  #     let(:user) { create(:user, admin: true) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to permit_action(:update) }
  #   end
  #
  #   context "when user is not an admin" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to forbid_action(:update) }
  #   end
  #
  #   context "when user is an owner" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { user }
  #
  #     it { is_expected.to permit_action(:update) }
  #   end
  # end
  #
  # describe "#edit?" do
  #   context "when user is an admin" do
  #     let(:user) { create(:user, admin: true) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to permit_action(:edit) }
  #   end
  #
  #   context "when user is not an admin" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to forbid_action(:edit) }
  #   end
  #
  #   context "when user is an owner" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { user }
  #
  #     it { is_expected.to permit_action(:edit) }
  #   end
  # end
  #
  # describe "#destroy?" do
  #   context "when user is an admin" do
  #     let(:user) { create(:user, admin: true) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to permit_action(:destroy) }
  #   end
  #
  #   context "when user is not an admin" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { is_expected.to forbid_action(:destroy) }
  #   end
  #
  #   context "when user is an owner" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { user }
  #
  #     it { is_expected.to forbid_action(:destroy) }
  #   end
  # end
  #
  # describe "#permitted_attributes" do
  #   context "when user is an admin" do
  #     context "when user is an admin and record is the same user as admin" do
  #       let(:user) { create(:user, admin: true) }
  #
  #       let(:record) { user }
  #
  #       it { expect(subject.permitted_attributes).to eq(described_class::FIELDS) }
  #     end
  #
  #     context "when user is an admin and record is not the same user as admin" do
  #       let(:user) { create(:user, admin: true) }
  #
  #       let(:record) { create(:user, admin: false) }
  #
  #       it { expect(subject.permitted_attributes).to eq(described_class::FIELDS + [:admin]) }
  #     end
  #   end
  #
  #   context "when user is not an admin" do
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:record) { create(:user, admin: false) }
  #
  #     it { expect(subject.permitted_attributes).to eq(described_class::FIELDS) }
  #   end
  # end
end

RSpec.describe Errbit::UserPolicy::Scope do
  # describe "#resolve" do
  #   context "when user is an admin" do
  #     let(:admin) { create(:user, admin: true) }
  #
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:scope) { User }
  #
  #     subject { described_class.new(admin, scope) }
  #
  #     it { expect(subject.resolve).to eq([admin, user]) }
  #   end
  #
  #   context "when user is not an admin" do
  #     let!(:admin) { create(:user, admin: true) }
  #
  #     let(:user) { create(:user, admin: false) }
  #
  #     let(:scope) { User }
  #
  #     subject { described_class.new(user, scope) }
  #
  #     it { expect(subject.resolve).to eq([user]) }
  #   end
  # end
end
