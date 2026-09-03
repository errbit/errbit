# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Locales do
  before { described_class.reload! }

  it "discovers the Errbit UI catalogs" do
    expect(described_class.selectable.map(&:identifier)).to eq(["en", "es", "pt-BR"])
  end

  it "returns catalog autonyms" do
    expect(described_class.selectable.map(&:name)).to eq(["English", "Español", "Português (Brasil)"])
  end

  it "normalizes regional identifiers" do
    expect(described_class.normalize("PT_br")).to eq("pt-BR")
  end

  it "preserves script casing in locale identifiers" do
    expect(described_class.normalize("SR_latn_rs")).to eq("sr-Latn-RS")
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

  it "rejects duplicate YAML keys" do
    Tempfile.create(["duplicate-locale", ".yml"]) do |file|
      file.write("en:\n  locale_name: English\n  locale_name: Other\n")
      file.close

      expect do
        described_class.send(:validate_unique_keys!, Pathname(file.path))
      end.to raise_error(Errbit::Locales::CatalogError, /duplicate key: locale_name/)
    end
  end

  it "rejects invalid locale filenames" do
    Tempfile.create(["invalid_locale", ".yml"]) do |file|
      file.write("invalid_locale:\n  locale_name: Invalid\n")
      file.close
      allow(Rails.root).to receive(:glob).and_return([Pathname(file.path)])

      expect { described_class.selectable }
        .to raise_error(Errbit::Locales::CatalogError, /invalid locale filename/)
    end
  end

  it "rejects noncanonical locale filenames" do
    expect { described_class.send(:validate_identifier!, Pathname("pt-br.yml"), "pt-br") }
      .to raise_error(Errbit::Locales::CatalogError, /canonical locale identifier/)
  end

  it "rejects changed interpolation variables" do
    expect do
      described_class.send(:validate_translation_shape!, Pathname("pt.yml"), "pt",
        {"message" => "%{total} errors"}, {"message" => "%{count} errors"})
    end.to raise_error(Errbit::Locales::CatalogError, /interpolation variables/)
  end

  it "allows valid additional pluralization keys" do
    expect do
      described_class.send(:validate_translation_shape!, Pathname("ru.yml"), "ru",
        {"message" => {"one" => "ошибка", "few" => "ошибки", "many" => "ошибок", "other" => "ошибок"}},
        {"message" => {"one" => "error", "other" => "errors"}})
    end.not_to raise_error
  end

  it "rejects invalid pluralization keys" do
    expect do
      described_class.send(:validate_translation_shape!, Pathname("pt.yml"), "pt",
        {"message" => {"bogus" => "erros", "other" => "erros"}},
        {"message" => {"one" => "error", "other" => "errors"}})
    end.to raise_error(Errbit::Locales::CatalogError, /pluralization keys/)
  end

  it "rejects incomplete pluralization keys for the locale" do
    expect do
      described_class.send(:validate_translation_shape!, Pathname("ru.yml"), "ru",
        {"message" => {"other" => "ошибок"}},
        {"message" => {"one" => "error", "other" => "errors"}})
    end.to raise_error(Errbit::Locales::CatalogError, /pluralization keys/)
  end

  it "rejects changed translation value types" do
    expect do
      described_class.send(:validate_translation_shape!, Pathname("pt.yml"), "pt",
        {"message" => {"other" => "erros"}}, {"message" => "errors"})
    end.to raise_error(Errbit::Locales::CatalogError, /value type/)
  end
end
