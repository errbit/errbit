describe NotificationServices::SlackService, type: 'model' do
  let(:notice) { Fabricate :notice }
  let(:problem) { notice.problem }
  let(:service_url) do
    "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX"
  end
  let(:service) do
    Fabricate :slack_notification_service, app:         notice.app,
                                           service_url: service_url,
                                           room_id:     room_id
  end

  # faraday stubbing
  let(:payload_hash) do
    {
      username:    "Errbit",
      icon_url:    "https://raw.githubusercontent.com/errbit/errbit/master/docs/notifications/slack/errbit.png",
      channel:     room_id,
      attachments: [
        {
          fallback:   service.message_for_slack(problem),
          title:      problem.message.to_s.truncate(100),
          title_link: problem.url,
          text:       problem.where,
          color:      "#D00000",
          fields:     [
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
              value: problem.notices_count.try(:to_s),
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
    }
  end

  it "should have icon for slack" do
    expect(Rails.root.join("docs/notifications/slack/errbit.png")).to exist
  end

  context 'with room_id' do
    let(:room_id) do
      "#general"
    end

    it "should send a notification to Slack with hook url and channel" do
      payload = payload_hash.to_json

      expect(HTTParty).to receive(:post).
        with(service.service_url, body: payload, headers: { "Content-Type" => "application/json" }).
        and_return(true)

      service.create_notification(problem)
    end
  end

  context 'without room_id' do
    let(:room_id) { nil }

    it "should send a notification to Slack with hook url and without channel" do
      payload = payload_hash.except(:channel).to_json

      expect(HTTParty).to receive(:post).
        with(service.service_url, body: payload, headers: { "Content-Type" => "application/json" }).
        and_return(true)

      service.create_notification(problem)
    end
  end
end
