# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ProblemRecacher do
  describe ".run" do
    let(:problem) { create(:errbit_problem) }
    let(:err) { create(:errbit_err, problem: problem) }

    it "recaches each problem and destroys problems with no notices" do
      empty_problem = create(:errbit_problem)
      create(:errbit_notice, err: err)

      described_class.run

      expect(Errbit::Problem.where(id: empty_problem.id)).to be_empty
      expect(problem.reload.notices_count).to eq(1)
    end
  end
end
