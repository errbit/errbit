require 'spec_helper'

describe ResolvedProblemClearer do
  let(:resolved_problem_clearer) {
    ResolvedProblemClearer.new
  }
  describe "#execute" do
    let!(:problems) {
      [
        Fabricate(:problem),
        Fabricate(:problem),
        Fabricate(:problem)
      ]
    }
    context 'without problem resolved' do
      it 'do nothing' do
        expect {
          expect(resolved_problem_clearer.execute).to eq 0
        }.to_not change {
          Problem.count
        }
      end
    end

    context "with problem resolve" do
      before do
        problems.first.resolve!
        problems.second.resolve!
      end

      it 'delete problem resolve' do
        expect {
          expect(resolved_problem_clearer.execute).to eq 2
        }.to change {
          Problem.count
        }.by(-2)
        expect(Problem.where(:id => problems.first.id).first).to be_nil
        expect(Problem.where(:id => problems.second.id).first).to be_nil
      end
    end
  end
end
