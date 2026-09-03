# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::UserPolicy do
  let(:user) { create(:errbit_user, admin: false) }
  let(:other_user) { create(:errbit_user, admin: false) }

  it "allows users to manage themselves" do
    policy = described_class.new(user, user)

    expect(policy.show?).to eq(true)
    expect(policy.update?).to eq(true)
  end

  it "prevents non-admins from managing other users" do
    policy = described_class.new(user, other_user)

    expect(policy.show?).to eq(false)
    expect(policy.update?).to eq(false)
  end

  it "allows admins to manage other users but not destroy themselves" do
    admin = create(:errbit_user, admin: true)

    expect(described_class.new(admin, other_user).destroy?).to eq(true)
    expect(described_class.new(admin, admin).destroy?).to eq(false)
  end
end
