class NotificationServices::WebhookService < NotificationService
  LABEL = "LARK"
  FIELDS = [
    [:api_token, {
      placeholder: 'URL to receive a POST request when an error occurs',
      label:       'URL'
    }]
  ]

  def check_params
    if FIELDS.detect { |f| self[f[0]].blank? }
      errors.add :base, 'You must specify the URL'
    end
  end

  def post_payload(problem)
    {
      msg_type: 'interactive',
      card: {
        config: {
          wide_screen_mode: true,
          enable_forward: true
        },
        header: {
          title: {
            content: problem.message.to_s.truncate(100)
          }
        },
        elements: [
          {
            tag: 'div',
            text: {
              tag: 'plain_text',
              content: problem.where
            },
            fields: post_payload_fields(problem)
          }
        ]
      }
    }.compact.to_json
  end

  def create_notification(problem)
    HTTParty.post(api_token, headers: { 'Content-Type' => 'application/json', 'User-Agent' => 'Errbit' }, body: post_payload(problem))
  end

  private

  def post_payload_fields(problem)
    [
      {
        "is_short": true,
        "text": {
          "tag": "lark_md",
          "content": "**Application:**\n#{problem.app.name}"
        }
      },
      {
        "is_short": true,
        "text": {
          "tag": "lark_md",
          "content": "**Environment:**\n#{problem.environment}"
        }
      },
      {
        "is_short": false,
        "text": {
          "tag": "lark_md",
          "content": "**Backtrace:**\n#{backtrace_lines(problem)}"
        }
      }
    ]
  end

  def backtrace_line(line)
    path = line.decorated_path.gsub(%r{</?strong>}, '')
    "#{path}#{line.file_name}:#{line.number} → #{line.method}\n"
  end
end
