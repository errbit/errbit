# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ResolvedProblemClearer do
  describe "#execute" do
    let!(:problems) { create_list(:errbit_problem, 3) }

    context "without resolved problems" do
      it "does nothing" do
        expect { expect(subject.execute).to eq(0) }.not_to change(Errbit::Problem, :count)
      end
    end

    context "with resolved problems" do
      before do
        problems.first.resolve!
        problems.second.resolve!
      end

      it "deletes the resolved problems" do
        expect { expect(subject.execute).to eq(2) }.to change(Errbit::Problem, :count).by(-2)

        expect(Errbit::Problem.where(id: problems.first.id)).to be_empty
        expect(Errbit::Problem.where(id: problems.second.id)).to be_empty
      end
    end
  end
end
