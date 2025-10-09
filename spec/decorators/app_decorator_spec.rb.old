# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppDecorator, type: :decorator do
  describe "#email_at_notices" do
    it "return the list separate by comma" do
      expect(described_class.new(double(email_at_notices: [2, 3])).email_at_notices).to eq("2, 3")
    end
  end

  describe "#notify_user_display" do
    it "return display:none if notify" do
      expect(described_class.new(double(notify_all_users: true)).notify_user_display).to eq("display: none;")
    end

    it "return blank if no notify" do
      expect(described_class.new(double(notify_all_users: false)).notify_user_display).to eq("")
    end
  end

  describe "#notify_err_display" do
    it "return display:none if no notify" do
      expect(described_class.new(double(notify_on_errs: false)).notify_err_display).to eq("display: none;")
    end

    it "return blank if no notify" do
      expect(described_class.new(double(notify_on_errs: true)).notify_err_display).to eq("")
    end
  end

  describe "#custom_backtrace_url" do
    it "should correctly replace the unescaped fields" do
      dbl = double(repo_branch: "feature/branch",
        custom_backtrace_url_template: "https://example.com/repo/name/src/branch/%{branch}/%{file}#L%{line}")

      expect(described_class.new(dbl).custom_backtrace_url("test/file.rb", 42))
        .to eq("https://example.com/repo/name/src/branch/feature/branch/test/file.rb#L42")
    end

    it "should correctly replace the escaped fields" do
      dbl = double(repo_branch: "feature/branch",
        custom_backtrace_url_template: "https://example.com/repo/name/src/branch/%{ebranch}/%{efile}#L%{line}")

      expect(described_class.new(dbl).custom_backtrace_url("test/file.rb", 42))
        .to eq("https://example.com/repo/name/src/branch/feature%2Fbranch/test%2Ffile.rb#L42")
    end
  end
end
