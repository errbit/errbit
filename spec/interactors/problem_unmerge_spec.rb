require 'spec_helper'

describe ProblemUnmerge do
  let(:problem1) { Fabricate(:notice).problem }
  let(:problem2) { Fabricate(:notice).problem }

  describe "#execute" do
    let(:merged_problem) { Problem.merge!(problem1, problem2) }
    let!(:problem_unmerge) { ProblemUnmerge.new(merged_problem) }

    it 'creates new problems as needed' do
      expect {
        problem_unmerge.execute
      }.to change(Problem, :count).by(+1)
    end

    it 'update problem cache' do
      expect(ProblemUpdaterCache).to receive(:new).with(kind_of(Problem)).and_return(double(:update => true)).twice
      ProblemUnmerge.new(merged_problem).execute
    end
  end
end
