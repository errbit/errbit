# frozen_string_literal: true

module Errbit
  module NotificationServices
    class SlackService < NotificationService
      CHANNEL_NAME_REGEXP = /^#[a-z\d_-]+$/
      LABEL = "slack"
      FIELDS = NotificationService::FIELDS + [
        [:service_url, {placeholder: "Slack Hook URL", label: "Hook URL"}],
        [:room_id, {placeholder: "#general", label: "Notification channel"}]
      ]

      def check_params
        errors.add :service_url, "You must specify your Slack Hook url" if service_url.blank?

        if room_id.present? && !CHANNEL_NAME_REGEXP.match(room_id)
          errors.add :room_id, "Slack channel name must be lowercase, with no space, special character, or periods."
        end
      end

      def message_for_slack(problem)
        "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem.url}"
      end

      def post_payload(problem)
        {
          username: "Errbit",
          icon_url: "https://raw.githubusercontent.com/errbit/errbit/main/docs/notifications/slack/errbit.png",
          channel: room_id,
          attachments: [
            {
              fallback: message_for_slack(problem),
              title: problem.message.to_s.truncate(100),
              title_link: problem.url,
              text: problem.where,
              color: "#D00000",
              mrkdwn_in: ["fields"],
              fields: post_payload_fields(problem)
            }
          ]
        }.compact.to_json
      end

      def create_notification(problem)
        HTTParty.post(service_url, body: post_payload(problem), headers: {"Content-Type" => "application/json"})
      end

      def configured?
        service_url.present?
      end

      private

      def post_payload_fields(problem)
        [
          {title: "Application", value: problem.app.name, short: true},
          {title: "Environment", value: problem.environment, short: true},
          {title: "Times Occurred", value: problem.notices_count.try(:to_s), short: true},
          {title: "First Noticed", value: problem.first_notice_at.try(:localtime).try(:to_fs, :db), short: true}
        ]
      end
    end
  end
end
