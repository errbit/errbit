# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Callback on Comment", type: :model do
  context "when a Comment is saved" do
    let(:comment) { build(:comment) }

    context "and it is emailable?" do
      before { allow(comment).to receive(:emailable?).and_return(true) }

      it "should send an email notification" do
        expect(Mailer).to receive(:with).with(comment: comment) do
          double.tap do |a|
            expect(a).to receive(:comment_notification)
              .and_return(double("email", deliver_now: true))
          end
        end

        comment.save
      end
    end

    context "and it is not emailable?" do
      before { allow(comment).to receive(:emailable?).and_return(false) }

      it "should not send an email notification" do
        expect(Mailer).not_to receive(:with)

        comment.save
      end
    end
  end
end
