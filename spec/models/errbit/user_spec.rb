# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::User, type: :model do
  it { expect(subject).to be_an(Errbit::ApplicationRecord) }
end
