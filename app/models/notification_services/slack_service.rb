class NotificationServices::SlackService < NotificationService
  CHANNEL_NAME_REGEXP = /^#[a-z\d_-]+$/
  LABEL = "slack"
  FIELDS += [
    [:service_url, {
      placeholder: 'Slack Hook URL (https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXX)',
      label:       'Hook URL'
    }],
    [:room_id, {
      placeholder: '#general',
      label:       'Notification channel',
      hint:        'If empty Errbit will use the default channel for the webook'
    }]
  ]

  # Make room_id optional in case users want to use the default channel
  # setup on Slack when creating the webhook
  def check_params
    if service_url.blank?
      errors.add :service_url, "You must specify your Slack Hook url"
    end

    if room_id.present? && !CHANNEL_NAME_REGEXP.match(room_id)
      errors.add :room_id, "Slack channel name must be lowercase, with no space, special character, or periods."
    end
  end

  def message_for_slack(problem)
    recent = problem.notices.where(:created_at.gte => 5.minutes.ago).count
    message = problem.message.gsub(/\s+/," ").truncate(100)
    app = problem.app.name
    "#{app} - total:#{problem.notices_count}  5min:#{recent} <#{problem.url}|#{encode(message)}>"
  end

  def encode(str)
    str.gsub("&", "&amp;")
    .gsub("<", "&lt;")
    .gsub(">", "&gt;")
  end

  def post_payload(problem)
    {
      username:    "Errbit",
      icon_url:    "https://raw.githubusercontent.com/errbit/errbit/master/docs/notifications/slack/errbit.png",
      channel:     room_id,
      text:        message_for_slack(problem),
    }.compact.to_json # compact to remove empty channel in case it wasn't selected by user
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

private

  def post_payload_fields(problem)
    [
      { title: "Application", value: problem.app.name, short: true },
      { title: "Environment", value: problem.environment, short: true },
      { title: "Times Occurred", value: problem.notices_count.try(:to_s),
        short: true },
      { title: "First Noticed",
        value: problem.first_notice_at.try(:localtime).try(:to_s, :db),
        short: true },
      { title: "Backtrace", value: backtrace_lines(problem), short: false }
    ]
  end

  def backtrace_line(line)
    path = line.decorated_path.gsub(%r{</?strong>}, '')
    "#{path}#{line.file_name}:#{line.number} → #{line.method}\n"
  end

  def backtrace_lines(problem)
    notice = NoticeDecorator.new problem.notices.last
    return unless notice
    backtrace = notice.backtrace
    return unless backtrace

    output = ''
    backtrace.lines[0..4].each { |line| output << backtrace_line(line) }
    "```#{output}```"
  end
end
