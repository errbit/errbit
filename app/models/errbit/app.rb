# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
    has_many :watchers, class_name: "Errbit::Watcher", foreign_key: :errbit_app_id, dependent: :destroy

    has_many :problems, class_name: "Errbit::Problem", dependent: :destroy

    # has_many :problems, inverse_of: :app, dependent: :destroy

    def github_repo?
      github_repo.present?
    end

    def issue_tracker_configured?
      # issue_tracker.present? && issue_tracker.configured?
    end

    def notification_service_configured?
      # (notification_service.class < NotificationService) &&
      #   notification_service.configured?
    end

    def problem_count
      # @problem_count ||= problems.count
      0
    end
  end
end
