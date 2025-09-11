# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit, type: :model do
  specify { expect(described_class.table_name_prefix).to eq("errbit_") }
end
