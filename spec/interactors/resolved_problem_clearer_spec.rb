describe ResolvedProblemClearer do
  let(:resolved_problem_clearer) do
    ResolvedProblemClearer.new
  end
  describe "#execute" do
    let!(:problems) do
      [
        Fabricate(:problem),
        Fabricate(:problem),
        Fabricate(:problem)
      ]
    end
    context "without problem resolved" do
      it "do nothing" do
        expect do
          expect(resolved_problem_clearer.execute).to eq 0
        end.to_not change {
          Problem.count
        }
      end
      it "not compact database" do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        expect(Mongoid.default_client).to_not receive(:command).with(compact: an_instance_of(String))
        resolved_problem_clearer.execute
      end
    end

    context "with problem resolve" do
      before do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        allow(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)
        problems.first.resolve!
        problems.second.resolve!
      end

      it "delete problem resolve" do
        expect do
          expect(resolved_problem_clearer.execute).to eq 2
        end.to change {
          Problem.count
        }.by(-2)
        expect(Problem.where(_id: problems.first.id).first).to be_nil
        expect(Problem.where(_id: problems.second.id).first).to be_nil
      end

      it "compact database" do
        expect(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)
        resolved_problem_clearer.execute
      end
    end
  end
end
