# frozen_string_literal: true

module NotificationServices
  class PushoverService < NotificationService
    LABEL = "pushover"
    FIELDS += [
      [:api_token, {
        placeholder: "User Key",
        label: "User Key"
      }],
      [:subdomain, {
        placeholder: "Application API Token",
        label: "Application API Token"
      }]
    ]

    def check_params
      if FIELDS.detect { |f| self[f[0]].blank? }
        errors.add :base, "You must specify your User Key and Application API Token."
      end
    end

    def url
      "https://pushover.net/login"
    end

    def create_notification(problem)
      Pushover2::Message.new(
        token: subdomain,
        user: api_token,
        message: notification_description(problem),
        priority: 1,
        title: "Errbit Notification",
        url: "https://#{Config.errbit.host}/apps/#{problem.app.id}",
        url_title: "Link to error"
      ).push
    end
  end
end
