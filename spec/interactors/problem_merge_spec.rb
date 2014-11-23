require 'spec_helper'

describe ProblemMerge do
  let(:problem) { Fabricate(:problem_with_errs, opened_at: 4.weeks.ago) }
  let(:problem_1) { Fabricate(:problem_with_errs, opened_at: 5.weeks.ago) }

  describe "#initialize" do
    it "requires at least 2 unique problems" do
      expect {
        ProblemMerge.new(problem)
      }.to raise_error(ArgumentError)
    end

    it "extracts the first problem as merged_problem" do
      problem_merge = ProblemMerge.new(problem, problem, problem_1)
      expect(problem_merge.merged_problem).to eql problem
    end
    it "extracts the other problems as child_problems" do
      problem_merge = ProblemMerge.new(problem, problem, problem_1)
      expect(problem_merge.child_problems).to eql [problem_1]
    end
  end

  describe "#merge" do
    let!(:problem_merge) { ProblemMerge.new(problem, problem_1) }
    let(:first_errs) { problem.errs }
    let(:merged_errs) { problem_1.errs }
    let!(:notice) { Fabricate(:notice, err: first_errs.first) }
    let!(:notice_1) { Fabricate(:notice, err: merged_errs.first) }
    let!(:comment) { Fabricate(:comment, err: problem.errs.first ) }
    let!(:comment_2) { Fabricate(:comment, err: problem_1.errs.first, user: comment.user ) }

    it "deletes all but one of the problems" do
      expect {
        problem_merge.merge
      }.to change(Problem, :count).by(-1)
    end

    it "associates all errs with the remaining problem" do
      problem_merge.merge
      expect(problem.reload.errs.map(&:id).sort).to eq (first_errs | merged_errs).map(&:id).sort
    end

    it "associates all comments with the remaining problem" do
      problem.comments(true)
      problem_1.comments(true)
      
      expect {
        problem_merge.merge
      }.to change {
        problem.comments.count
      }.from(1).to(2)
      expect(comment_2.reload.problem).to eq problem
    end

    it "updates the problem's cached attributes" do
      expect(ProblemUpdaterCache).to receive(:new).with(problem).and_return(double(update: true))
      problem_merge.merge
    end
  end
end
