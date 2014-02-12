require 'spec_helper'

describe "Callback on Comment" do
  context 'when a Comment is saved' do
    let(:comment) { Fabricate.build(:comment) }

    context 'and it is emailable?' do
      before { comment.stub(:emailable?).and_return(true) }

      it 'should send an email notification' do
        expect(Mailer).to receive(:comment_notification).
          with(comment).
          and_return(double('email', :deliver => true))
        comment.save
      end
    end

    context 'and it is not emailable?' do
      before { comment.stub(:emailable?).and_return(false) }

      it 'should not send an email notification' do
        expect(Mailer).to_not receive(:comment_notification)
        comment.save
      end
    end
  end
end
