# frozen_string_literal: true

require "rails_helper"

RSpec.describe Problem, type: :model do
  let(:problem) { create(:problem_with_errs) }

  let(:problem_1) { create(:problem_with_errs) }

  describe ".merge!" do
    it "failed if less than 2 uniq problem pass in args" do
      expect do
        Problem.merge!(problem)
      end.to raise_error(ArgumentError, "need at least 2 unique problems")
    end

    it "extract first problem like merged_problem" do
      expect(Problem.merge!(problem, problem, problem_1)).to eq(problem)
    end

    it "extract other problem like child_problems" do
      expect { Problem.merge!(problem, problem, problem_1) }.not_to raise_error
    end
  end

  describe ".merge! with two problems" do
    let(:first_errs) { problem.errs }

    let(:merged_errs) { problem_1.errs }

    let!(:notice) { create(:notice, err: first_errs.first) }

    let!(:notice_1) { create(:notice, err: merged_errs.first) }

    it "delete one of problem" do
      expect do
        Problem.merge!(problem, problem_1)
      end.to change(Problem, :count).by(-1)
    end

    it "move all err in one problem" do
      Problem.merge!(problem, problem_1)
      expect(problem.reload.errs.map(&:id).sort).to eq((first_errs | merged_errs).map(&:id).sort)
    end

    it "keeps notices from the merged problem" do
      Problem.merge!(problem, problem_1)

      expect(Notice.where(_id: notice_1.id).entries).not_to be_empty
      expect(notice_1.reload.err.problem).to eq(problem)
    end

    it "keeps the issue link" do
      problem.update_attributes(issue_link: "http://foo.com", issue_type: "mock")
      Problem.merge!(problem, problem_1)
      expect(problem.reload.issue_link).to eq("http://foo.com")
      expect(problem.reload.issue_type).to eq("mock")
    end

    it "update problem cache" do
      expect(problem).to receive(:recache)
      Problem.merge!(problem, problem_1)
    end

    context "with problem with comment" do
      let!(:comment) { create(:comment, err: problem) }

      let!(:comment_2) { create(:comment, err: problem_1, user: comment.user) }

      it "merge comment" do
        expect do
          Problem.merge!(problem, problem_1)
        end.to change {
          problem.comments.size
        }.from(1).to(2)
        expect(comment_2.reload.err).to eq(problem)
      end
    end
  end
end
