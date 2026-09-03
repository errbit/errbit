# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::LocaleResolver do
  before do
    allow(Errbit::Locales).to receive(:identifiers).and_return(%w[en pt-BR pt-PT])
  end

  describe ".browser_locale" do
    it "prefers an exact regional match" do
      expect(described_class.browser_locale("pt-BR,pt;q=0.8,en;q=0.5")).to eq("pt-BR")
    end

    it "uses a generic language catalog when requested" do
      allow(Errbit::Locales).to receive(:identifiers).and_return(%w[en pt])

      expect(described_class.browser_locale("PT")).to eq("pt")
    end

    it "selects the first sorted regional catalog" do
      allow(Errbit::Locales).to receive(:identifiers).and_return(%w[en pt-PT pt-BR])

      expect(described_class.browser_locale("pt")).to eq("pt-BR")
    end

    it "respects quality values and q=0 exclusions" do
      expect(described_class.browser_locale("pt-BR;q=0,pt-PT;q=0.8,en;q=0.5")).to eq("pt-PT")
    end

    it "does not select a regional catalog excluded by a generic q=0 range" do
      expect(described_class.browser_locale("pt-BR;q=0,pt;q=0.8")).to eq("pt-PT")
    end

    it "falls back when a generic q=0 range excludes every regional catalog" do
      expect(described_class.browser_locale("pt;q=0,en;q=0.5")).to eq("en")
    end

    it "falls back from an English regional request to English" do
      allow(Errbit::Locales).to receive(:identifiers).and_return(%w[en es])

      expect(described_class.browser_locale("en-US;q=1,es;q=0.8")).to eq("en")
    end

    it "ignores unsupported and wildcard values" do
      expect(described_class.browser_locale("fr, *;q=0.5")).to be_nil
    end

    it "ignores malformed values without raising" do
      expect { described_class.browser_locale("\u0000") }.not_to raise_error
    end
  end
end
