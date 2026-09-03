# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::AppDecorator, type: :decorator do
  describe "#notify_err_class" do
    it "returns hidden when notifications are disabled" do
      app = instance_double(Errbit::App, notify_on_errs: false)

      expect(described_class.new(app).notify_err_class).to eq("hidden")
    end

    it "returns blank when notifications are enabled" do
      app = instance_double(Errbit::App, notify_on_errs: true)

      expect(described_class.new(app).notify_err_class).to eq("")
    end
  end

  describe "#custom_notice_fingerprinter_class" do
    it "returns hidden when using the site fingerprinter" do
      fingerprinter = instance_double(Errbit::NoticeFingerprinter, attributes: {"source" => Errbit::SiteConfig::CONFIG_SOURCE_SITE})
      app = instance_double(Errbit::App, notice_fingerprinter: fingerprinter)

      expect(described_class.new(app).custom_notice_fingerprinter_class).to eq("hidden")
    end

    it "returns blank when using a custom fingerprinter" do
      fingerprinter = instance_double(Errbit::NoticeFingerprinter, attributes: {"source" => Errbit::SiteConfig::CONFIG_SOURCE_APP})
      app = instance_double(Errbit::App, notice_fingerprinter: fingerprinter)

      expect(described_class.new(app).custom_notice_fingerprinter_class).to eq("")
    end
  end
end
