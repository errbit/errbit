# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::AppDecorator, type: :decorator do
  describe "#email_at_notices" do
    it "returns the list joined by commas" do
      expect(described_class.new(double(email_at_notices: [2, 3])).email_at_notices).to eq("2, 3")
    end
  end

  describe "#notify_user_display" do
    it "returns display:none when notify_all_users is true" do
      expect(described_class.new(double(notify_all_users: true)).notify_user_display).to eq("display: none;")
    end

    it "returns blank when notify_all_users is false" do
      expect(described_class.new(double(notify_all_users: false)).notify_user_display).to eq("")
    end
  end

  describe "#notify_err_display" do
    it "returns display:none when notify_on_errs is false" do
      expect(described_class.new(double(notify_on_errs: false)).notify_err_display).to eq("display: none;")
    end

    it "returns blank when notify_on_errs is true" do
      expect(described_class.new(double(notify_on_errs: true)).notify_err_display).to eq("")
    end
  end

  describe "#custom_backtrace_url" do
    it "replaces unescaped fields in the template" do
      dbl = double(repo_branch: "feature/branch",
        custom_backtrace_url_template: "https://example.com/repo/name/src/branch/%{branch}/%{file}#L%{line}")

      expect(described_class.new(dbl).custom_backtrace_url("test/file.rb", 42))
        .to eq("https://example.com/repo/name/src/branch/feature/branch/test/file.rb#L42")
    end

    it "replaces escaped fields in the template" do
      dbl = double(repo_branch: "feature/branch",
        custom_backtrace_url_template: "https://example.com/repo/name/src/branch/%{ebranch}/%{efile}#L%{line}")

      expect(described_class.new(dbl).custom_backtrace_url("test/file.rb", 42))
        .to eq("https://example.com/repo/name/src/branch/feature%2Fbranch/test%2Ffile.rb#L42")
    end
  end

  describe "#use_site_fingerprinter" do
    it "is true when notice_fingerprinter is nil" do
      app = create(:errbit_app)
      # Errbit::App auto-builds a fingerprinter on create; explicitly drop it
      # to exercise the nil branch of the decorator.
      app.notice_fingerprinter.destroy
      app.reload

      expect(described_class.new(app).use_site_fingerprinter).to eq(true)
    end

    it "is true when the fingerprinter source is nil" do
      app = create(:errbit_app)
      app.notice_fingerprinter.update!(source: nil)

      expect(described_class.new(app.reload).use_site_fingerprinter).to eq(true)
    end

    it "is true when the fingerprinter source is 'site'" do
      app = create(:errbit_app)
      app.notice_fingerprinter.update!(source: Errbit::SiteConfig::CONFIG_SOURCE_SITE)

      expect(described_class.new(app.reload).use_site_fingerprinter).to eq(true)
    end

    it "is false when the fingerprinter source is not 'site'" do
      app = create(:errbit_app)
      app.notice_fingerprinter.update!(source: Errbit::SiteConfig::CONFIG_SOURCE_APP)

      expect(described_class.new(app.reload).use_site_fingerprinter).to eq(false)
    end
  end
end
