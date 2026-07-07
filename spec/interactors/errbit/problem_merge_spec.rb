# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ProblemMerge do
  let(:app) { create(:errbit_app) }
  let(:problem) { create(:errbit_problem, app: app) }
  let(:problem_1) { create(:errbit_problem, app: app) }

  before do
    create(:errbit_err, problem: problem)
    create(:errbit_err, problem: problem_1)
  end

  describe "#initialize" do
    it "raises when fewer than 2 unique problems are passed" do
      expect { described_class.new(problem) }.to raise_error(ArgumentError)
    end

    it "uses the first problem as merged_problem" do
      pm = described_class.new(problem, problem, problem_1)

      expect(pm.merged_problem).to eq(problem)
    end

    it "uses the remaining unique problems as child_problems" do
      pm = described_class.new(problem, problem, problem_1)

      expect(pm.child_problems).to eq([problem_1])
    end
  end

  describe "#merge" do
    let!(:problem_merge) { described_class.new(problem, problem_1) }
    let(:first_errs) { problem.errs.to_a }
    let(:merged_errs) { problem_1.errs.to_a }

    before do
      create(:errbit_notice, err: first_errs.first, app: app)
      create(:errbit_notice, err: merged_errs.first, app: app)
    end

    it "destroys one of the problems" do
      expect { problem_merge.merge }.to change(Errbit::Problem, :count).by(-1)
    end

    it "reassigns all errs to the merged problem" do
      expected_err_ids = (first_errs + merged_errs).map(&:id).sort

      problem_merge.merge

      expect(problem.reload.errs.pluck(:id).sort).to eq(expected_err_ids)
    end

    it "keeps the issue link on the merged problem" do
      problem.update!(issue_link: "http://foo.com", issue_type: "mock")

      problem_merge.merge

      expect(problem.reload.issue_link).to eq("http://foo.com")
      expect(problem.reload.issue_type).to eq("mock")
    end

    it "recaches the merged problem" do
      expect(problem).to receive(:recache)

      problem_merge.merge
    end

    context "with comments on both problems" do
      let(:user) { create(:errbit_user) }
      let!(:comment) { create(:errbit_comment, err: problem, user: user) }
      let!(:comment_2) { create(:errbit_comment, err: problem_1, user: user) }

      it "reassigns comments to the merged problem" do
        expect { problem_merge.merge }
          .to change { problem.reload.comments.size }.from(1).to(2)

        expect(comment_2.reload.err).to eq(problem)
      end
    end
  end
end
