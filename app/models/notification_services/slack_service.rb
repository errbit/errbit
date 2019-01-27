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
    "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem.url} #{authors_to_mention(problem).split("\n").join(', ')}"
  end

  def post_payload(problem)
    {
      username:    "Errbit",
      icon_url:    "https://raw.githubusercontent.com/errbit/errbit/master/docs/notifications/slack/errbit.png",
      channel:     room_id,
      attachments: [
        {
          fallback:   message_for_slack(problem),
          title:      notification_or_exception_emoji(problem) + ' ' + problem.message.to_s.truncate(100),
          title_link: problem.url,
          text:       problem.where,
          color:      notification_or_exception_color(problem),
          mrkdwn_in:  ["fields"],
          fields:     post_payload_fields(problem)
        }
      ]
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

  def notification_or_exception_emoji(problem)
    if problem.notification_not_exception?
      ':bell:'
    else
      ':rotating_light:'
    end
  end

  def notification_or_exception_color(problem)
    if problem.notification_not_exception?
      'warning'
    else
      'd00000'
    end
  end

  def authors_to_mention(problem)
    return 'N/A' if problem.assigned_to.nil?
    assigned_to_lines = ""
    problem.assigned_to.each do |assignee|
      slack_user_id = problem.app.slack_user_id_map[assignee]
      next unless slack_user_id.present?
      new_assigned_to_line = if slack_user_id.start_with?("S")
                               "<!subteam^#{slack_user_id}|#{assignee}>\n"
                             else
                               "<@#{slack_user_id}>\n"
      end
      assigned_to_lines += new_assigned_to_line
    end
    assigned_to_lines
  end

  def user_affected(problem)
    notice = problem.notices.last
    user_attributes = notice.user_attributes
    return 'N/A' unless user_attributes.present? && user_attributes['id'].present?
    "#{user_attributes['email']} (#{user_attributes['id']})"
  end

  def hostname(problem)
    notice = problem.notices.last
    env = notice.try(:server_environment) || {}
    env['hostname']
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
      { title: "Assigned To", value: authors_to_mention(problem), short: true },
      { title: "User", value: user_affected(problem), short: true },
      { title: "Host", value: hostname(problem), short: true },
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
