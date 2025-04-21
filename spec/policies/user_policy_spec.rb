# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class.new(user, record) }

  describe "#initialize" do
    context "when user not present" do
      let(:record) { Fabricate(:user) }

      let(:user) { nil }

      it { expect { subject }.to raise_error(Pundit::NotAuthorizedError) }
    end
  end

  describe "#index" do
    let(:record) { Fabricate(:user) }

    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      it { is_expected.to forbid_action(:index) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      it { is_expected.to forbid_action(:index) }
    end
  end

  describe "#show?" do
    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to permit_action(:show) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to forbid_action(:show) }
    end

    context "when user is an owner" do
      let(:user) { Fabricate(:user) }

      let(:record) { user }

      it { is_expected.to permit_action(:show) }
    end
  end

  describe "#create?" do
    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      let(:record) { User.new }

      it { is_expected.to permit_action(:create) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      let(:record) { User.new }

      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "#new?" do
    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      let(:record) { User.new }

      it { is_expected.to permit_action(:new) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      let(:record) { User.new }

      it { is_expected.to forbid_action(:new) }
    end
  end

  describe "#update?" do
    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to permit_action(:update) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to forbid_action(:update) }
    end

    context "when user is an owner" do
      let(:user) { Fabricate(:user) }

      let(:record) { user }

      it { is_expected.to permit_action(:update) }
    end
  end

  describe "#edit?" do
    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to permit_action(:edit) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to forbid_action(:edit) }
    end

    context "when user is an owner" do
      let(:user) { Fabricate(:user) }

      let(:record) { user }

      it { is_expected.to permit_action(:edit) }
    end
  end

  describe "#destroy?" do
    context "when user is an admin" do
      let(:user) { Fabricate(:admin) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to permit_action(:destroy) }
    end

    context "when user is not an admin" do
      let(:user) { Fabricate(:user) }

      let(:record) { Fabricate(:user) }

      it { is_expected.to forbid_action(:destroy) }
    end

    context "when user is an owner" do
      let(:user) { Fabricate(:user) }

      let(:record) { user }

      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
