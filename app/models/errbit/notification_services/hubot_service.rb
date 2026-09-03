# frozen_string_literal: true

module Errbit
  module NotificationServices
    class HubotService < NotificationService
      LABEL = "hubot"
      FIELDS = NotificationService::FIELDS + [
        [:service_url, {placeholder: "http://hubot.example.com/hubot/errbit", label: "Hubot URL"}],
        [:room_id, {placeholder: "room", label: "Room"}]
      ]

      def check_params
        errors.add :service_url, "is required" if service_url.blank?
      end

      def create_notification(problem)
        HTTParty.post(service_url, body: {room: room_id, message: notification_description(problem)})
      end

      def configured?
        service_url.present?
      end
    end
  end
end
