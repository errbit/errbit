# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
    has_many :watchers,
      class_name: "Errbit::Watcher",
      foreign_key: :errbit_app_id,
      dependent: :destroy

    has_many :problems,
      class_name: "Errbit::Problem",
      foreign_key: :errbit_app_id,
      dependent: :destroy

    # embeds_one :issue_tracker, class_name: "IssueTracker"
    # embeds_one :notification_service

    has_one :notice_fingerprinter,
      class_name: "Errbit::NoticeFingerprinter",
      foreign_key: :errbit_app_id,
      dependent: :destroy

    scope :search, ->(value) { where(arel_table[:name].matches("%#{value}%")) }

    # @param user [User]
    def watched_by?(user)
      watchers.exists?(user: user)
    end

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

    def use_site_fingerprinter
      notice_fingerprinter.source == "site"
    end
  end
end
