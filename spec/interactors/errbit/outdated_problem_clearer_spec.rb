# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::OutdatedProblemClearer do
  before do
    allow(Errbit::Config).to receive(:notice_deprecation_days).and_return(7)
  end

  describe "#execute" do
    let!(:problems) { create_list(:errbit_problem, 3) }

    context "without old problems" do
      it "does nothing" do
        expect { expect(subject.execute).to eq(0) }.not_to change(Errbit::Problem, :count)
      end
    end

    context "with old problems" do
      before do
        problems.first.update!(last_notice_at: 1.year.ago)
        problems.second.update!(last_notice_at: 1.year.ago)
      end

      it "deletes the outdated problems" do
        expect { expect(subject.execute).to eq(2) }.to change(Errbit::Problem, :count).by(-2)

        expect(Errbit::Problem.where(id: problems.first.id)).to be_empty
        expect(Errbit::Problem.where(id: problems.second.id)).to be_empty
      end
    end
  end
end
