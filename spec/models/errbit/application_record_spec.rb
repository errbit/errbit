# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ApplicationRecord, type: :model do
  it { expect(described_class.abstract_class).to eq(true) }

  it { expect(ActiveRecord.application_record_class).to eq(described_class) }
end
