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
      it 'not repair database' do
        Mongoid.config.master.should_receive(:command).and_call_original
        Mongoid.config.master.should_not_receive(:command).with({:repairDatabase => 1})
        resolved_problem_clearer.execute
      end
    end

    context "with problem resolve" do
      before do
        Mongoid.config.master.stub(:command).and_call_original
        Mongoid.config.master.stub(:command).with({:repairDatabase => 1})
        problems.first.resolve!
        problems.second.resolve!
      end

      it 'delete problem resolve' do
        expect {
          expect(resolved_problem_clearer.execute).to eq 2
        }.to change {
          Problem.count
        }.by(-2)
        expect(Problem.where(:_id => problems.first.id).first).to be_nil
        expect(Problem.where(:_id => problems.second.id).first).to be_nil
      end

      it 'repair database' do
        Mongoid.config.master.should_receive(:command).and_call_original
        Mongoid.config.master.should_receive(:command).with({:repairDatabase => 1})
        resolved_problem_clearer.execute
      end
    end
  end
end
