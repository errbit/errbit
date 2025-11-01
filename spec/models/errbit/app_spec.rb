# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::App, type: :model do
  it { expect(subject).to be_an(Errbit::ApplicationRecord) }

  it { is_expected.to have_many(:watchers).dependent(:destroy) }
end
