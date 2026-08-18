# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::AppPolicy do
  let(:app) { create(:errbit_app) }

  it "allows anyone logged in to show apps" do
    user = create(:errbit_user)

    expect(described_class.new(user, app).show?).to eq(true)
  end

  it "allows only admins to manage apps" do
    user = create(:errbit_user, admin: false)
    admin = create(:errbit_user, admin: true)

    expect(described_class.new(user, app).create?).to eq(false)
    expect(described_class.new(admin, app).create?).to eq(true)
  end
end
