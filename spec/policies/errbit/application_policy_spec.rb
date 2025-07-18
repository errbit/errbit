# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ApplicationPolicy do
  let(:record) { create(:errbit_user, admin: false) }

  subject { described_class.new(user, record) }

  context "when user present" do
    context "when user is an admin" do
      let(:user) { create(:errbit_user, admin: true) }

      it { is_expected.to forbid_all_actions }
    end

    context "when user is not an admin" do
      let(:user) { create(:errbit_user, admin: false) }

      it { is_expected.to forbid_all_actions }
    end
  end

  context "when user not present" do
    let(:user) { nil }

    it { expect { subject }.to raise_error(Pundit::NotAuthorizedError) }
  end

  describe "#permitted_attributes" do
    let(:user) { create(:errbit_user, admin: false) }

    it { expect { subject.permitted_attributes }.to raise_error(NotImplementedError, "You must define #permitted_attributes in Errbit::ApplicationPolicy") }
  end
end

RSpec.describe Errbit::ApplicationPolicy::Scope do
  describe "#initialize" do
    context "when user is not present" do
      let(:user) { nil }

      let(:scope) { Errbit::User }

      it { expect { described_class.new(user, scope) }.to raise_error(Pundit::NotAuthorizedError) }
    end

    context "when user is present" do
      let(:user) { create(:errbit_user, admin: false) }

      let(:scope) { double }

      it { expect { described_class.new(user, scope) }.not_to raise_error }
    end
  end

  describe "#resolve" do
    let(:user) { create(:errbit_user, admin: false) }

    let(:scope) { double }

    subject { described_class.new(user, scope) }

    it { expect { subject.resolve }.to raise_error(NotImplementedError, "You must define #resolve in Errbit::ApplicationPolicy::Scope") }
  end
end
