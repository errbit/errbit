require 'spec_helper'

describe CommentObserver do
  context 'when a Comment is saved' do
    let(:comment) { Fabricate.build(:comment) }

    context 'and it is emailable?' do
      before { comment.stub(:emailable?).and_return(true) }

      it 'should send an email notification' do
        Mailer.should_receive(:comment_notification).
          with(comment).
          and_return(mock('email', :deliver => true))
        comment.save
      end
    end

    context 'and it is not emailable?' do
      before { comment.stub(:emailable?).and_return(false) }

      it 'should not send an email notification' do
        Mailer.should_not_receive(:comment_notification)
        comment.save
      end
    end
  end
end
