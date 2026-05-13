# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Backtrace, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_backtraces table" do
    expect(described_class.table_name).to eq("errbit_backtraces")
  end

  describe "constants" do
    it "exposes IN_APP_PATH" do
      expect(described_class::IN_APP_PATH).to be_a(Regexp)
    end

    it "exposes GEMS_PATH" do
      expect(described_class::GEMS_PATH).to be_a(Regexp)
    end
  end

  describe ".generate_fingerprint" do
    it "returns a SHA1 hex digest of the lines joined as strings" do
      lines = [{"number" => "1", "file" => "a.rb", "method" => "foo"}]

      expect(described_class.generate_fingerprint(lines))
        .to eq(Digest::SHA1.hexdigest(lines.map(&:to_s).join))
    end

    it "produces the same fingerprint for identical lines" do
      lines = [{"number" => "1"}, {"number" => "2"}]

      expect(described_class.generate_fingerprint(lines))
        .to eq(described_class.generate_fingerprint(lines))
    end

    it "produces different fingerprints for different lines" do
      first = described_class.generate_fingerprint([{"number" => "1"}])
      second = described_class.generate_fingerprint([{"number" => "2"}])

      expect(first).not_to eq(second)
    end
  end

  describe ".find_or_create" do
    let(:lines) do
      [
        {"number" => "123", "file" => "/some/path/to.rb", "method" => "abc"},
        {"number" => "345", "file" => "/path/to.rb", "method" => "dowhat"}
      ]
    end
    let(:fingerprint) { described_class.generate_fingerprint(lines) }

    it "creates a new backtrace" do
      backtrace = described_class.find_or_create(lines)

      expect(backtrace).to be_persisted
      expect(backtrace.lines).to eq(lines)
      expect(backtrace.fingerprint).to eq(fingerprint)
    end

    it "creates only one backtrace for two identical line sets" do
      described_class.find_or_create(lines)
      described_class.find_or_create(lines)

      expect(described_class.where(fingerprint: fingerprint).count).to eq(1)
    end

    it "returns the existing backtrace when called with matching lines" do
      first = described_class.find_or_create(lines)
      second = described_class.find_or_create(lines)

      expect(second).to eq(first)
    end
  end
end
