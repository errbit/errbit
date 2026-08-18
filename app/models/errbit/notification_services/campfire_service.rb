# frozen_string_literal: true

module Errbit
  module NotificationServices
    class CampfireService < NotificationService
      LABEL = "campfire"
      FIELDS = NotificationService::FIELDS + [
        [:subdomain, {placeholder: "account", label: "Subdomain"}],
        [:api_token, {placeholder: "api token", label: "API token"}],
        [:room_id, {placeholder: "room id", label: "Room ID"}]
      ]

      def check_params
        FIELDS.each do |field, _opts|
          errors.add field, "is required" if send(field).blank?
        end
      end

      def create_notification(problem)
        Campy::Room.new(subdomain, api_token, room_id).speak(notification_description(problem))
      end
    end
  end
end
