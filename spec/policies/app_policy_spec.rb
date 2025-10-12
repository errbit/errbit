# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppPolicy do
  subject { described_class.new(user, record) }

  describe "#initialize" do
    context "when user not present" do
      let(:record) { create(:app) }

      let(:user) { nil }

      it { expect { subject }.to raise_error(Pundit::NotAuthorizedError) }
    end
  end

  describe "#index" do
    let(:record) { create(:app) }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to forbid_action(:index) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to forbid_action(:index) }
    end
  end

  describe "#show?" do
    let(:record) { create(:app) }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to permit_action(:show) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to permit_action(:show) }
    end
  end

  describe "#create?" do
    let(:record) { App.new }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to permit_action(:create) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "#new?" do
    let(:record) { App.new }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to permit_action(:new) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to forbid_action(:new) }
    end
  end

  describe "#update?" do
    let(:record) { create(:app) }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to permit_action(:update) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to forbid_action(:update) }
    end
  end

  describe "#edit?" do
    let(:record) { create(:app) }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to permit_action(:edit) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to forbid_action(:edit) }
    end
  end

  describe "#destroy?" do
    let(:record) { create(:app) }

    context "when user is an admin" do
      let(:user) { create(:user, admin: true) }

      it { is_expected.to permit_action(:destroy) }
    end

    context "when user is not an admin" do
      let(:user) { create(:user, admin: false) }

      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
