describe ProblemRecacher do
  let(:app) { Fabricate(:app) }
  let(:backtrace) do
    Fabricate(:backtrace)
  end

  before do
    notices

    NoticeRefingerprinter.run
    described_class.run
  end

  context "minor backtrace differences" do
    let(:notices) do
      line_numbers = [1, 1, 2, 2, 3]
      5.times.map do
        b = backtrace.clone
        b.lines[5][:number] = line_numbers.shift
        b.save!
        notice = Fabricate(:notice, backtrace: b, app: app)
        notice.save!
        notice
      end
    end

    it "has three problems for the five notices" do
      expect(Notice.count).to eq(5)
      expect(Problem.count).to eq(3)
    end

    it "the problems have the right cached attributes" do
      problem = notices.first.reload.problem

      expect(problem.notices_count).to eq(2)
    end
  end
end
