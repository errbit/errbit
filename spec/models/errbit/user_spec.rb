# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::User, type: :model do
  it { expect(subject).to be_an(Errbit::ApplicationRecord) }

  it { expect(described_class::PER_PAGE).to eq(30) }

  it { is_expected.to validate_presence_of(:name) }

  describe "#github_login" do
    # subject { build(:errbit_user, email: "me@example.com", github_login: "biow0lf") }

    it { expect(subject).to validate_uniqueness_of(:github_login).allow_nil }
  end

  describe "#per_page" do
    context "when default" do
      subject { create(:errbit_user, per_page: nil) }

      it { expect(subject.per_page).to eq(30) }
    end

    context "when custom" do
      subject { create(:errbit_user, per_page: 31) }

      it { expect(subject.per_page).to eq(31) }
    end
  end

  describe "#attributes_for_super_diff" do
    subject { create(:errbit_user) }

    it { expect(subject.attributes_for_super_diff).to eq(id: subject.id, name: subject.name) }
  end

  # private methods

  describe "#generate_authentication_token" do

  end
end
