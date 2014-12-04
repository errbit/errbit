class NotificationServices::SlackService < NotificationService
  Label = "slack"
  Fields += [
    [:webhook_url, {
      :placeholder => 'Slack Webhook URL',
      :label => 'Token'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, "You must specify your Slack webhook url."
    end
  end

  def url
    webhook_url
  end

  def message_for_slack(problem)
    "*#{problem.app.name}* (#{problem.environment}) - *#{problem.where}*: `#{problem.error_class}: #{problem.message}` - #{problem.notices_count}) times, <#{problem_url(problem)}|view details>"
  end

  def post_payload(problem)
    payload = {:text => message_for_slack(problem) }
    payload[:channel] = room_id unless room_id.empty?
    payload.to_json
  end

  def create_notification(problem)
    HTTParty.post(url, :body => post_payload(problem), :headers => { 'Content-Type' => 'application/json' })
  end
end
