describe NotificationServices::TelegramService, type: "model" do
  it "should send notifications to Telegrams bot API" do
    notice = Fabricate :notice
    notification_service = Fabricate :telegram_notification_service, app: notice.app
    problem = notice.problem

    expect(HTTParty).to receive(:post).and_return(true)

    notification_service.create_notification(problem)
  end
end
