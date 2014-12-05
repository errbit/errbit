class NotificationServices::SlackService < NotificationService
  Label = "slack"

  # NotificationService wants api_token to be the primary and required field, so we'll use that.
  Fields += [
    [:api_token, {
      :placeholder => 'Slack Webhook URL',
      :label => 'Webhook URL'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, "You must specify your Slack Webhook url."
    end
  end

  def url
    api_token
  end

  def slack_escape(str)
    str.gsub('`','\'')
  end

  def message_for_slack(problem)
    "*#{slack_escape(problem.app.name)}* (_#{slack_escape(problem.environment)}_) - *#{slack_escape(problem.where)}*:\n`#{slack_escape(problem.error_class)}: #{slack_escape(problem.message)}`\n<#{slack_escape(problem_url(problem))}|view details>   _error count: #{problem.notices_count}_"
  end

  def post_payload(problem)
    {:text => message_for_slack(problem) }.to_json
  end

  def create_notification(problem)
    HTTParty.post(url, :body => post_payload(problem), :headers => { 'Content-Type' => 'application/json' })
  end
end
