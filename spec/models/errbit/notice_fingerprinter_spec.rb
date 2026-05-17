# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::NoticeFingerprinter, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_notice_fingerprinters table" do
    expect(described_class.table_name).to eq("errbit_notice_fingerprinters")
  end

  describe "defaults" do
    let(:fingerprinter) { described_class.new }

    it { expect(fingerprinter.error_class).to eq(true) }
    it { expect(fingerprinter.message).to eq(true) }
    it { expect(fingerprinter.component).to eq(true) }
    it { expect(fingerprinter.action).to eq(true) }
    it { expect(fingerprinter.environment_name).to eq(true) }
    it { expect(fingerprinter.backtrace_lines).to eq(-1) }
    it { expect(fingerprinter.source).to be_nil }
  end

  describe "associations" do
    it "belongs to an app (optional)" do
      expect(described_class.new(app: nil).valid?).to eq(true)
    end

    it "is auto-built when its app is created" do
      app = create(:errbit_app)

      expect(app.notice_fingerprinter).to be_present
      expect(app.notice_fingerprinter.app).to eq(app)
    end

    it "is destroyed when its app is destroyed" do
      app = create(:errbit_app)
      app.notice_fingerprinter # force load

      expect {
        app.destroy
      }.to change(described_class, :count).by(-1)
    end
  end

  describe "#generate" do
    let(:fingerprinter) { described_class.new }
    let(:notice) { create(:errbit_notice) }
    let(:backtrace) { create(:errbit_backtrace) }

    it "generates the same fingerprint for the same notice" do
      f_1 = fingerprinter.generate("123", notice, backtrace)
      f_2 = fingerprinter.generate("123", notice, backtrace)

      expect(f_1).to eq(f_2)
    end

    ["error_class", "message", "component", "action", "environment_name"].each do |attr|
      it "affects the fingerprint when #{attr} is false" do
        f_1 = fingerprinter.generate("123", notice, backtrace)

        fingerprinter.send(:"#{attr}=", false)
        f_2 = fingerprinter.generate("123", notice, backtrace)

        expect(f_1).not_to eq(f_2)
      end
    end

    it "is affected by backtrace_lines config" do
      f_1 = fingerprinter.generate("123", notice, backtrace)

      fingerprinter.backtrace_lines = 1
      f_2 = fingerprinter.generate("123", notice, backtrace)

      expect(f_1).not_to eq(f_2)
    end

    context "two backtraces with the same first two lines" do
      let(:backtrace_1) { create(:errbit_backtrace) }
      let(:backtrace_2) { create(:errbit_backtrace) }

      before do
        backtrace_1.lines[0] = backtrace_2.lines[0]
        backtrace_1.lines[1] = backtrace_2.lines[1]
        backtrace_1.lines[2] = {"number" => 1, "file" => "a", "method" => "b"}
      end

      it "produces the same fingerprint when considering two lines" do
        fingerprinter.backtrace_lines = 2

        f_1 = fingerprinter.generate("123", notice, backtrace_1)
        f_2 = fingerprinter.generate("123", notice, backtrace_2)

        expect(f_1).to eq(f_2)
      end

      it "produces different fingerprints when considering three lines" do
        fingerprinter.backtrace_lines = 3

        f_1 = fingerprinter.generate("123", notice, backtrace_1)
        f_2 = fingerprinter.generate("123", notice, backtrace_2)

        expect(f_1).not_to eq(f_2)
      end
    end

    context "with nil backtrace" do
      it "produces the same fingerprint across calls" do
        f_1 = fingerprinter.generate("123", notice, nil)
        f_2 = fingerprinter.generate("123", notice, nil)

        expect(f_1).to eq(f_2)
      end
    end
  end
end
