class NotificationServices::SlackService < NotificationService
  LABEL = "slack"
  FIELDS += [
    [:service_url, {
      placeholder: 'Slack Hook URL (https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX)',
      label:       'Hook URL'
    }]
  ]

  def check_params
    if FIELDS.detect { |f| self[f[0]].blank? }
      errors.add :base, "You must specify your Slack Hook url."
    end
  end

  def message_for_slack(problem)
    "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem.url}"
  end

  def post_payload(problem)
    {
      attachments: [
        {
          fallback: message_for_slack(problem),
          pretext:  "<#{problem_url(problem)}|Errbit - #{problem.app.name}: #{problem.error_class}>",
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
  end

  def create_notification(problem)
    HTTParty.post(
      service_url,
      body:    post_payload(problem),
      headers: {
        'Content-Type' => 'application/json'
      }
    )
  end

  def configured?
    service_url.present?
  end
end
