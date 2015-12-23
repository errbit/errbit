describe NotificationServices::SlackService, type: 'model' do
  it "it should send a notification to Slack with hook url" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service, app: notice.app, service_url: "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX"
    problem = notice.problem

    # faraday stubbing
    payload = {
      attachments: [
        {
          fallback: notification_service.message_for_slack(problem),
          pretext:  "<#{problem.url}|Errbit - #{problem.app.name}: #{problem.error_class}>",
          color:    "#D00000",
          fields:   [
            {
              title: "Environment",
              value: problem.environment,
              short: false
            },
            {
              title: "Location",
              value: problem.where,
              short: false
            },
            {
              title: "Message",
              value: problem.message.to_s,
              short: false
            },
            {
              title: "First Noticed",
              value: problem.first_notice_at,
              short: false
            },
            {
              title: "Last Noticed",
              value: problem.last_notice_at,
              short: false
            },
            {
              title: "Times Occurred",
              value: problem.notices_count,
              short: false
            }
          ]
        }
      ]
    }.to_json
    expect(HTTParty).to receive(:post).with(notification_service.service_url, body: payload, headers: { "Content-Type" => "application/json" }).and_return(true)

    notification_service.create_notification(problem)
  end
end
