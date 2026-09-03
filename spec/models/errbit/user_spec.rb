# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::User, type: :model do
  it "generates an authentication token" do
    user = create(:errbit_user)

    expect(user.authentication_token).to be_present
  end

  it "allows GitHub users without passwords" do
    user = described_class.new(email: "github@example.com", name: "GitHub", github_login: "octocat")

    expect(user).to be_valid
  end
end
