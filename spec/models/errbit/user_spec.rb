# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::User, type: :model do
  it { expect(subject).to be_an(Errbit::ApplicationRecord) }

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_uniqueness_of(:github_login).allow_nil }
end
