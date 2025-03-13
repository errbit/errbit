describe OutdatedProblemClearer do
  before do
    allow(Errbit::Config).to receive(:notice_deprecation_days).and_return(7)
  end

  let(:outdated_problem_clearer) do
    OutdatedProblemClearer.new
  end
  describe "#execute" do
    let!(:problems) do
      [
        Fabricate(:problem),
        Fabricate(:problem),
        Fabricate(:problem)
      ]
    end
    context "without old problems" do
      it "do nothing" do
        expect do
          expect(outdated_problem_clearer.execute).to eq 0
        end.to_not change {
          Problem.count
        }
      end
      it "not compact database" do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        expect(Mongoid.default_client).to_not receive(:command).with(compact: an_instance_of(String))
        outdated_problem_clearer.execute
      end
    end

    context "with old problems" do
      before do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        allow(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)
        problems.first.update(last_notice_at: Time.zone.at(946_684_800.0))
        problems.second.update(last_notice_at: Time.zone.at(946_684_800.0))
      end

      it "deletes old problems" do
        expect do
          expect(outdated_problem_clearer.execute).to eq 2
        end.to change {
          Problem.count
        }.by(-2)
        expect(Problem.where(_id: problems.first.id).first).to be_nil
        expect(Problem.where(_id: problems.second.id).first).to be_nil
      end

      it "compact database" do
        expect(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)
        outdated_problem_clearer.execute
      end
    end
  end
end
