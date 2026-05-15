# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::NoticeRefingerprinter do
  let(:app) { create(:errbit_app) }
  let!(:fingerprinter) { create(:errbit_notice_fingerprinter, app: app) }

  describe ".run" do
    context "with identical backtraces" do
      let(:backtrace) { create(:errbit_backtrace) }

      before do
        5.times { create(:errbit_notice, backtrace: backtrace, app: app) }
      end

      it "collapses all five notices into a single err" do
        expect { described_class.run }.to change(Errbit::Err, :count).to(1)
      end
    end

    context "with three distinct backtraces" do
      before do
        3.times do
          create(:errbit_notice, app: app)
        end
        # Create one more notice sharing the first backtrace.
        first_bt = Errbit::Backtrace.first
        create(:errbit_notice, app: app, backtrace: first_bt)
      end

      it "produces one err per unique backtrace fingerprint" do
        expect { described_class.run }.to change(Errbit::Err, :count).to(3)
      end
    end

    it "destroys orphaned errs (with no notices) at the end" do
      orphan = create(:errbit_err, problem: create(:errbit_problem, app: app))

      expect { described_class.run }.to change { Errbit::Err.where(id: orphan.id).count }.from(1).to(0)
    end
  end

  describe ".refingerprint" do
    it "reassigns the notice to a freshly-computed err" do
      notice = create(:errbit_notice, app: app)
      original_err = notice.err

      described_class.refingerprint(notice.reload)

      expect(notice.reload.err).not_to eq(original_err)
      expect(notice.err.fingerprint).to eq(
        fingerprinter.generate(app.api_key, notice, notice.backtrace)
      )
    end
  end
end
