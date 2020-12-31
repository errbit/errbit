describe NotificationServices::WebhookService, type: 'model' do
  it "it should send a notification to a user-specified URL" do
    notice = Fabricate :notice
    notification_service = Fabricate :webhook_notification_service, app: notice.app
    problem = notice.problem

    payload = notification_service.message_for_webhook(problem)
    expect(HTTParty).to receive(:post).with(notification_service.api_token, headers: { 'Content-Type' => 'application/json', 'User-Agent' => 'Errbit' }, body: payload.to_json).and_return(true)

    notification_service.create_notification(problem)
  end

  context "#message_for_webhook" do
    it "should return an hash with all the keys nested inside 'problem' key" do
      notice = Fabricate :notice
      notification_service = Fabricate :webhook_notification_service, app: notice.app
      problem = notice.problem

      payload = notification_service.message_for_webhook(problem)

      expect(payload[:problem]).to be_a(Hash)
    end
  end
end
