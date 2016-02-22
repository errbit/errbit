describe NotificationServices::SlackService, type: 'model' do
  it "it should send a notification to Slack with hook url" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service,
      app: notice.app,
      service_url: "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX"
    problem = notice.problem

    # faraday stubbing
    payload = {
      username: "Errbit",
      icon_emoji: ":collision:",
      attachments: [
        {
          fallback:   notification_service.message_for_slack(problem),
          title:      problem.message.to_s.truncate(100),
          title_link: problem.url,
          text:       problem.where,
          color:      "#D00000",
          fields: [
            {
              title: "Application",
              value: problem.app.name,
              short: true
            },
            {
              title: "Environment",
              value: problem.environment,
              short: true
            },
            {
              title: "Times Occurred",
              value: problem.notices_count,
              short: true
            },
            {
              title: "First Noticed",
              value: problem.first_notice_at.try(:to_s, :db),
              short: true
            }
          ]
        }
      ]
    }.to_json
    expect(HTTParty).to receive(:post).with(notification_service.service_url, body: payload, headers: { "Content-Type" => "application/json" }).and_return(true)

    notification_service.create_notification(problem)
  end
end
