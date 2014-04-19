class NotificationServices::SlackService < NotificationService
  Label = "slack"
  Fields += [
    [:subdomain, {
      :placeholder => 'subdomain',
      :label => 'Subdomain portion for Slack service'
    }],
    [:api_token, {
      :placeholder => 'Slack Integration Token',
      :label => 'Token'
    }],
    [:room_id, {
      :placeholder => '#general',
      :label => 'Room where Slack should notify'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? unless f[0] == :room_id }
      errors.add :base, "You must specify your Slack subdomain and token."
    end
  end

  def url
    "https://#{subdomain}.slack.com/services/hooks/incoming-webhook?token=#{api_token}"
  end

  def message_for_slack(problem)
    "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem_url(problem)}"
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
