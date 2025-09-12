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
end
