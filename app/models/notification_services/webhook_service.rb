# frozen_string_literal: true

module NotificationServices
  class WebhookService < NotificationService
    LABEL = "webhook"
    FIELDS = [
      [:api_token, {
        placeholder: "URL to receive a POST request when an error occurs",
        label: "URL"
      }]
    ]

    def check_params
      if FIELDS.detect { |f| self[f[0]].blank? }
        errors.add :base, "You must specify the URL"
      end
    end

    def message_for_webhook(problem)
      {
        problem: {url: problem.url}.merge!(problem.as_json)
      }
    end

    def create_notification(problem)
      HTTParty.post(api_token, headers: {"Content-Type" => "application/json", "User-Agent" => "Errbit"}, body: message_for_webhook(problem).to_json)
    end
  end
end
