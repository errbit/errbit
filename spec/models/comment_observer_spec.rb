describe "Callback on Comment", type: 'model' do
  context 'when a Comment is saved' do
    let(:comment) { Fabricate.build(:comment) }

    context 'and it is emailable?' do
      before { allow(comment).to receive(:emailable?).and_return(true) }

      it 'should send an email notification' do
        expect(Mailer).to receive(:comment_notification).
          with(comment).
          and_return(double('email', deliver_now: true))
        comment.save
      end
    end

    context 'and it is not emailable?' do
      before { allow(comment).to receive(:emailable?).and_return(false) }

      it 'should not send an email notification' do
        expect(Mailer).to_not receive(:comment_notification)
        comment.save
      end
    end
  end
end
