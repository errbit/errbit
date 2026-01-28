# frozen_string_literal: true

require "rails_helper"

RSpec.describe NoticeFingerprinter, type: :model do
  let(:fingerprinter) { described_class.new }
  let(:notice) { create(:notice) }
  let(:backtrace) { create(:backtrace) }

  describe "#generate" do
    it "generates the same fingerprint for the same notice" do
      f_1 = fingerprinter.generate("123", notice, backtrace)
      f_2 = fingerprinter.generate("123", notice, backtrace)
      expect(f_1).to eq(f_2)
    end

    ["error_class", "message", "component", "action", "environment_name"].each do |i|
      it "affects the fingerprint when #{i} is false" do
        f_1 = fingerprinter.generate("123", notice, backtrace)
        f_2 = fingerprinter.generate("123", notice, backtrace)

        fingerprinter.send(:"#{i}=", false)
        f_3 = fingerprinter.generate("123", notice, backtrace)

        expect(f_1).to eq(f_2)
        expect(f_1).not_to eq(f_3)
      end
    end

    it "affects the fingerprint with different backtrace_lines config" do
      f_1 = fingerprinter.generate("123", notice, backtrace)
      f_2 = fingerprinter.generate("123", notice, backtrace)

      fingerprinter.backtrace_lines = 2
      f_3 = fingerprinter.generate("123", notice, backtrace)

      expect(f_1).to eq(f_2)
      expect(f_1).not_to eq(f_3)
    end

    context "two backtraces have the same first two lines" do
      let(:backtrace_1) { create(:backtrace) }
      let(:backtrace_2) { create(:backtrace) }

      before do
        backtrace_1.lines[0] = backtrace_2.lines[0]
        backtrace_1.lines[1] = backtrace_2.lines[1]
        backtrace_1.lines[2] = {number: 1, file: "a", method: :b}
      end

      it "has the same fingerprint when only considering two lines" do
        fingerprinter.backtrace_lines = 2
        f_1 = fingerprinter.generate("123", notice, backtrace_1)
        f_2 = fingerprinter.generate("123", notice, backtrace_2)

        expect(f_1).to eq(f_2)
      end

      it "has a different fingerprint when considering three lines" do
        fingerprinter.backtrace_lines = 3
        f_1 = fingerprinter.generate("123", notice, backtrace_1)
        f_2 = fingerprinter.generate("123", notice, backtrace_2)

        expect(f_1).not_to eq(f_2)
      end
    end

    context "two notices with no backtrace" do
      it "has the same fingerprint" do
        f_1 = fingerprinter.generate("123", notice, nil)
        f_2 = fingerprinter.generate("123", notice, nil)

        expect(f_1).to eq(f_2)
      end
    end
  end
end
