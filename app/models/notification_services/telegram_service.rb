class NotificationServices::TelegramService < NotificationService
  LABEL = "telegram"
  FIELDS += [
    [:bot_token, {
      placeholder: "The Bot token you received from the BotFather.",
      label:       "Bot Token"
    }],
    [:chat_ids_raw, {
      placeholder: "A comma-seperated list of chat IDs to send notifications to.",
      label:       "Chat IDs",
      hint:        "You can find out the ID for your account by poking @myidbot."
    }]
  ]

  def check_params
    errors.add(:base, "You must specify a bot token") if bot_token.blank?

    errors.add(:base, "Field 'Chat IDs' contains an invalid value") \
      if not chat_ids.all? { |s| Integer(s) rescue false }
  end

  def problem_text(problem)
    t = ["<strong>#{problem.app.name} error</strong> in environment #{problem.environment}"]
    t << "Location: #{problem.where}" if problem.where.present?
    t << "<pre>#{problem.message.to_s.truncate(100)}</pre>"
    t << "<a href=\"#{app_problem_url(problem.app, problem)}\">View on Errbit</a>"
    t.join("\n")
  end

  def create_notification(problem)
    url = "https://api.telegram.org/bot#{bot_token}/sendMessage"
    text = problem_text(problem)

    chat_ids.each do |chat_id|
      HTTParty.post(url, body: {
        chat_id: chat_id,
        text: text,
        parse_mode: "HTML"
      })
    end
  end

  def configured?
    bot_token.present? and chat_ids_raw.present?
  end

private

  def chat_ids
    chat_ids_raw.split(",").map(&:strip)
  end
end
