# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::SiteConfig, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_site_configs table" do
    expect(described_class.table_name).to eq("errbit_site_configs")
  end

  describe "fingerprinter field defaults" do
    subject(:config) { described_class.create! }

    it { expect(config.error_class).to eq(true) }
    it { expect(config.message).to eq(true) }
    it { expect(config.component).to eq(true) }
    it { expect(config.action).to eq(true) }
    it { expect(config.environment_name).to eq(true) }
    it { expect(config.backtrace_lines).to eq(-1) }
  end

  describe ".document" do
    it "creates a single SiteConfig when none exists" do
      expect {
        described_class.document
      }.to change(described_class, :count).by(1)
    end

    it "returns the existing SiteConfig when one already exists" do
      existing = described_class.create!

      result = described_class.document

      expect(result).to eq(existing)
      expect(described_class.count).to eq(1)
    end

    it "is idempotent across repeated calls" do
      first = described_class.document
      second = described_class.document

      expect(second).to eq(first)
      expect(described_class.count).to eq(1)
    end
  end

  describe "#notice_fingerprinter_attributes" do
    it "returns the fingerprinter fields plus a site source" do
      config = described_class.create!(
        error_class: true,
        message: false,
        backtrace_lines: 5,
        component: true,
        action: false,
        environment_name: true
      )

      expect(config.notice_fingerprinter_attributes).to eq(
        error_class: true,
        message: false,
        backtrace_lines: 5,
        component: true,
        action: false,
        environment_name: true,
        source: described_class::CONFIG_SOURCE_SITE
      )
    end

    it "always marks source as CONFIG_SOURCE_SITE" do
      config = described_class.create!

      expect(config.notice_fingerprinter_attributes[:source]).to eq("site")
    end
  end

  describe "source constants" do
    it { expect(described_class::CONFIG_SOURCE_SITE).to eq("site") }
    it { expect(described_class::CONFIG_SOURCE_APP).to eq("app") }
  end
end
