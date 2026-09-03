# frozen_string_literal: true

module Errbit
  module NotificationServices
    class HoiioService < NotificationService
      LABEL = "hoiio"
      FIELDS = NotificationService::FIELDS + [
        [:api_token, {placeholder: "app id", label: "App ID"}],
        [:service, {placeholder: "access token", label: "Access token"}],
        [:user_id, {placeholder: "recipient number", label: "Recipient number"}],
        [:room_id, {placeholder: "sender name", label: "Sender name"}]
      ]

      def check_params
        FIELDS.each do |field, _opts|
          errors.add field, "is required" if send(field).blank?
        end
      end

      def create_notification(problem)
        Hoi::SMS.send(user_id, notification_description(problem), from: room_id, app_id: api_token, access_token: service)
      end
    end
  end
end
