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
end
