describe NotificationServices::CampfireService, type: 'model' do
  it "it should send a notification to campfire" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :campfire_notification_service, app: notice.app
    problem = notice.problem

    # campy stubbing
    campy = double('CampfireService')
    allow(Campy::Room).to receive(:new).and_return(campy)
    allow(campy).to receive(:speak).and_return(true)

    # assert
    expect(campy).to receive(:speak)

    notification_service.create_notification(problem)
  end
end
