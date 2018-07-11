describe NotificationServices::SlackService, type: 'model' do
  let(:backtrace) do
    Fabricate :backtrace, lines: [
      { number: 22, file: "/path/to/file/1.rb", method: 'first_method' },
      { number: 44, file: "/path/to/file/2.rb", method: 'second_method' },
      { number: 11, file: "/path/to/file/3.rb", method: 'third_method' },
      { number: 103, file: "/path/to/file/4.rb", method: 'fourth_method' },
      { number: 923, file: "/path/to/file/5.rb", method: 'fifth_method' },
      { number: 8, file: "/path/to/file/6.rb", method: 'sixth_method' }
    ]
  end
  let(:notice) { Fabricate :notice, backtrace: backtrace }
  let(:problem) { notice.problem }
  let(:service_url) do
    "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX"
  end
  let(:service) do
    Fabricate :slack_notification_service, app:         notice.app,
                                           service_url: service_url,
                                           room_id:     room_id
  end
  let(:room_id) do
    "#general"
  end
  let(:backtrace_lines) do
    lines = "/path/to/file/1.rb:22 → first_method\n" \
            "/path/to/file/2.rb:44 → second_method\n" \
            "/path/to/file/3.rb:11 → third_method\n" \
            "/path/to/file/4.rb:103 → fourth_method\n" \
            "/path/to/file/5.rb:923 → fifth_method\n"
    "```#{lines}```"
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
          mrkdwn_in:  ["fields"],
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
              value: problem.first_notice_at.try(:localtime).try(:to_s, :db),
              short: true
            },
            {
              title: "Backtrace",
              value: backtrace_lines,
              short: false
            }
          ]
        }
      ]
    }
  end

  it "should have icon for slack" do
    expect(Rails.root.join("docs/notifications/slack/errbit.png")).to exist
  end

  context 'Validations' do
    it 'validates presence of service_url' do
      service.service_url = ""
      service.valid?

      expect(service.errors[:service_url]).
        to include("You must specify your Slack Hook url")

      service.service_url = service_url
      service.valid?

      expect(service.errors[:service_url]).to be_blank
    end

    it 'validates format of room_id' do
      service.room_id = "INVALID NAME"
      service.valid?

      expect(service.errors[:room_id]).
        to include("Slack channel name must be lowercase, with no space, special character, or periods.")

      service.room_id = "#valid-room-name"
      service.valid?

      expect(service.errors[:room_id]).to be_blank
    end
  end

  context 'with room_id' do
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
