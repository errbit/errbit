describe ProblemMerge do
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:problem_1) { Fabricate(:problem_with_errs) }

  describe "#initialize" do
    it "failed if less than 2 uniq problem pass in args" do
      expect do
        ProblemMerge.new(problem)
      end.to raise_error(ArgumentError)
    end

    it "extract first problem like merged_problem" do
      problem_merge = ProblemMerge.new(problem, problem, problem_1)
      expect(problem_merge.merged_problem).to eql problem
    end
    it "extract other problem like child_problems" do
      problem_merge = ProblemMerge.new(problem, problem, problem_1)
      expect(problem_merge.child_problems).to eql [problem_1]
    end
  end

  describe "#merge" do
    let!(:problem_merge) do
      ProblemMerge.new(problem, problem_1)
    end
    let(:first_errs) { problem.errs }
    let(:merged_errs) { problem_1.errs }
    let!(:notice) { Fabricate(:notice, err: first_errs.first) }
    let!(:notice_1) { Fabricate(:notice, err: merged_errs.first) }

    it "delete one of problem" do
      expect do
        problem_merge.merge
      end.to change(Problem, :count).by(-1)
    end

    it "move all err in one problem" do
      problem_merge.merge
      expect(problem.reload.errs.map(&:id).sort).to eq((first_errs | merged_errs).map(&:id).sort)
    end

    it "keeps the issue link" do
      problem.update_attributes(issue_link: "http://foo.com", issue_type: "mock")
      problem_merge.merge
      expect(problem.reload.issue_link).to eq "http://foo.com"
      expect(problem.reload.issue_type).to eq "mock"
    end

    it "update problem cache" do
      expect(problem).to receive(:recache)
      problem_merge.merge
    end

    context "with problem with comment" do
      let!(:comment) { Fabricate(:comment, err: problem) }
      let!(:comment_2) { Fabricate(:comment, err: problem_1, user: comment.user) }
      it "merge comment" do
        expect do
          problem_merge.merge
        end.to change {
          problem.comments.size
        }.from(1).to(2)
        expect(comment_2.reload.err).to eq problem
      end
    end
  end
end
