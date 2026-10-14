# frozen_string_literal: true

require "rails_helper"

RSpec.describe Problem, type: :model do
  describe ".clear_resolved!" do
    let!(:problems) { create_list(:problem, 3) }

    context "without problem resolved" do
      it "do nothing" do
        expect do
          expect(described_class.clear_resolved!).to eq(0)
        end.not_to change(Problem, :count)
      end

      it "not compact database" do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        expect(Mongoid.default_client).not_to receive(:command).with(compact: an_instance_of(String))
        described_class.clear_resolved!
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
          expect(described_class.clear_resolved!).to eq(2)
        end.to change(Problem, :count).by(-2)

        expect(Problem.where(_id: problems.first.id).first).to eq(nil)
        expect(Problem.where(_id: problems.second.id).first).to eq(nil)
      end

      it "compact database" do
        expect(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)

        described_class.clear_resolved!
      end
    end
  end
end
