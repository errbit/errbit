# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Backtrace, type: :model do
  it "deduplicates backtraces by generated fingerprint" do
    lines = [{"file" => "app.rb", "number" => 1}]

    first = described_class.find_or_create(lines)
    second = described_class.find_or_create(lines)

    expect(second).to eq(first)
    expect(described_class.count).to eq(1)
  end
end
