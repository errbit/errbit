describe NotificationService::SlackService, type: 'model' do
  it "it should send a notification to Slack with hook url" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service, :app => notice.app, :service_url => "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX"
    problem = notice.problem

    # faraday stubbing
    payload = {:text => notification_service.message_for_slack(problem)}.to_json
    expect(HTTParty).to receive(:post).with(notification_service.service_url, :body => payload, :headers => {"Content-Type" => "application/json"}).and_return(true)

    notification_service.create_notification(problem)
  end
end
