# frozen_string_literal: true

module Errbit
  class NotificationService < ApplicationRecord
    LABEL = ""

    include Rails.application.routes.url_helpers

    default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
    default_url_options[:port] = ActionMailer::Base.default_url_options[:port]

    serialize :notify_at_notices, type: Array, coder: YAML

    belongs_to :app,
      class_name: "Errbit::App",
      foreign_key: :errbit_app_id,
      inverse_of: :notification_service,
      optional: true

    validate :check_params

    FIELDS = if Errbit::Config.per_app_notify_at_notices
      [
        [:notify_at_notices,
          {
            placeholder: "comma separated numbers or simply 0 for every notice",
            label: "notify on errors (0 for all errors)"
          }]
      ]
    else
      []
    end

    def notify_at_notices
      Errbit::Config.per_app_notify_at_notices ? (super.presence || Errbit::Config.notify_at_notices) : Errbit::Config.notify_at_notices
    end

    # Subclasses are responsible for overwriting this method.
    def check_params
      true
    end

    def notification_description(problem)
      "[#{problem.environment}][#{problem.where}] #{problem.message.to_s.truncate(100)}"
    end

    def url
    end

    def self.label
      self::LABEL
    end

    def label
      self.class.label
    end

    def configured?
      api_token.present?
    end
  end
end
