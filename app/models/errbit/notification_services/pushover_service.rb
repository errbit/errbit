# frozen_string_literal: true

module Errbit
  module NotificationServices
    class PushoverService < NotificationService
      LABEL = "pushover"
      FIELDS = NotificationService::FIELDS + [
        [:api_token, {placeholder: "application token", label: "Application token"}],
        [:user_id, {placeholder: "user key", label: "User key"}]
      ]

      def check_params
        FIELDS.each do |field, _opts|
          errors.add field, "is required" if send(field).blank?
        end
      end

      def create_notification(problem)
        Pushover.notification(
          message: notification_description(problem),
          title: "Errbit",
          url: problem.url,
          url_title: "View problem",
          token: api_token,
          user: user_id
        ).push
      end
    end
  end
end
