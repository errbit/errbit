# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Locales do
  before { described_class.reload! }

  it "discovers the Errbit UI catalogs" do
    expect(described_class.selectable.map(&:identifier)).to eq(%w[en pt-BR])
  end

  it "returns catalog autonyms" do
    expect(described_class.selectable.map(&:name)).to eq(["English", "Português (Brasil)"])
  end

  it "normalizes regional identifiers" do
    expect(described_class.normalize("PT_br")).to eq("pt-BR")
  end

  it "does not treat framework-only locales as selectable" do
    expect(described_class).not_to include("fr")
  end

  it "falls back to English for a missing non-English translation" do
    backend = I18n.backend
    fallback = I18n.fallbacks
    exception_handler = I18n.exception_handler
    fallback_backend = I18n::Backend::Simple.new
    fallback_backend.extend(I18n::Backend::Fallbacks)
    I18n.backend = fallback_backend
    I18n.fallbacks = I18n::Locale::Fallbacks.new
    I18n.fallbacks.defaults = [:en]
    I18n.exception_handler = I18n::ExceptionHandler.new
    I18n.backend.store_translations(:en, fallback_probe: "English")

    expect(I18n.t(:fallback_probe, locale: :pt)).to eq("English")
  ensure
    I18n.backend = backend
    I18n.fallbacks = fallback
    I18n.exception_handler = exception_handler
  end
end
