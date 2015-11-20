describe NotificationServices::PushoverService, type: 'model' do
  it "it should send a notification to Pushover" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :pushover_notification_service, app: notice.app
    problem = notice.problem

    # hoi stubbing
    notification = double('PushoverService')
    allow(Rushover::Client).to receive(:new).and_return(notification)
    allow(notification).to receive(:notify).and_return(true)

    # assert
    expect(notification).to receive(:notify)

    notification_service.create_notification(problem)
  end
end
