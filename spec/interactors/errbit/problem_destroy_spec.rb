# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ProblemDestroy do
  let(:problem_destroy) { described_class.new(problem) }

  context "in unit form" do
    let(:problem) do
      problem = Errbit::Problem.new
      allow(problem).to receive(:errs).and_return(double(:errs, pluck: [11, 22]))
      allow(problem).to receive(:comments).and_return(double(:comments, pluck: [111, 222]))
      allow(problem).to receive(:delete)
      problem
    end

    describe "#initialize" do
      it "takes a problem" do
        expect(problem_destroy.problem).to eq(problem)
      end
    end

    describe "#execute" do
      it "destroys the problem itself" do
        expect(problem).to receive(:delete)

        problem_destroy.execute
      end

      it "deletes all errs by id" do
        expect(Errbit::Err).to receive(:where).with(id: [11, 22]).and_call_original

        problem_destroy.execute
      end

      it "deletes all comments by id" do
        expect(Errbit::Comment).to receive(:where).with(id: [111, 222]).and_call_original

        problem_destroy.execute
      end

      it "deletes notices for the problem's errs" do
        expect(Errbit::Notice).to receive(:where).with(errbit_err_id: [11, 22]).and_call_original

        problem_destroy.execute
      end
    end
  end

  context "in integration form" do
    let!(:problem) { create(:errbit_problem) }
    let!(:comment_1) { create(:errbit_comment, err: problem) }
    let!(:comment_2) { create(:errbit_comment, err: problem) }
    let!(:err_1) { create(:errbit_err, problem: problem) }
    let!(:err_2) { create(:errbit_err, problem: problem) }
    let!(:notice_1_1) { create(:errbit_notice, err: err_1) }
    let!(:notice_1_2) { create(:errbit_notice, err: err_1) }
    let!(:notice_2_1) { create(:errbit_notice, err: err_2) }
    let!(:notice_2_2) { create(:errbit_notice, err: err_2) }

    it "destroys the problem, errs, comments, and notices" do
      problem_destroy.execute

      expect(Errbit::Problem.where(id: problem.id)).to be_empty
      expect(Errbit::Err.where(id: [err_1.id, err_2.id])).to be_empty
      expect(Errbit::Comment.where(id: [comment_1.id, comment_2.id])).to be_empty
      expect(Errbit::Notice.where(id: [notice_1_1.id, notice_1_2.id, notice_2_1.id, notice_2_2.id])).to be_empty
    end
  end

  describe ".execute" do
    let!(:problem_1) { create(:errbit_problem) }
    let!(:problem_2) { create(:errbit_problem) }

    it "destroys an array of problems and returns the count" do
      count = described_class.execute([problem_1, problem_2])

      expect(count).to eq(2)
      expect(Errbit::Problem.where(id: [problem_1.id, problem_2.id])).to be_empty
    end

    it "accepts a single problem" do
      count = described_class.execute(problem_1)

      expect(count).to eq(1)
      expect(Errbit::Problem.where(id: problem_1.id)).to be_empty
    end
  end
end
