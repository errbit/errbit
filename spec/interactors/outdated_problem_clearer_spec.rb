# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutdatedProblemClearer do
  describe "#execute" do
    let!(:problems) { create_list(:problem, 3) }

    context "without old problems" do
      it "do nothing" do
        expect do
          expect(subject.execute).to eq(0)
        end.not_to change(Problem, :count)
      end

      it "not compact database" do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        expect(Mongoid.default_client).not_to receive(:command).with(compact: an_instance_of(String))
        subject.execute
      end
    end

    context "with old problems" do
      before do
        allow(Mongoid.default_client).to receive(:command).and_call_original
        allow(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)
        problems.first.update!(last_notice_at: 8.days.ago)
        problems.second.update!(last_notice_at: 8.days.ago)
      end

      it "deletes old problems" do
        expect do
          expect(subject.execute).to eq(2)
        end.to change(Problem, :count).by(-2)

        expect(Problem.count).to eq(1)
      end

      it "compact database" do
        expect(Mongoid.default_client).to receive(:command).with(compact: an_instance_of(String)).at_least(1)

        subject.execute
      end
    end
  end
end
