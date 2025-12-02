# frozen_string_literal: true

require "rails_helper"

RSpec.describe NoticeRefingerprinter do
  let(:app) { create(:app) }

  let(:backtrace) { create(:backtrace) }

  before do
    notices
  end

  context "identical backtraces" do
    let(:notices) do
      5.times.map do
        notice = create(:notice, backtrace: backtrace, app: app)
        notice.save!
        notice
      end
    end

    it "has only one err" do
      described_class.run

      expect(Err.count).to eq(1)
    end
  end

  context "minor backtrace differences" do
    let(:notices) do
      line_numbers = [1, 1, 2, 2, 3]
      5.times.map do
        b = backtrace.clone
        b.lines[5][:number] = line_numbers.shift
        b.save!
        notice = create(:notice, backtrace: b, app: app)
        notice.save!
      end
    end

    it "has three errs with default fingerprinter" do
      described_class.run

      expect(Err.count).to eq(3)
    end

    it "has one err when limiting backtrace line count" do
      fingerprinter = app.notice_fingerprinter
      fingerprinter.backtrace_lines = 4
      fingerprinter.save!

      described_class.run

      expect(Err.count).to eq(1)
    end
  end
end
