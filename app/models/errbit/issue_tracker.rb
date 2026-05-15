# frozen_string_literal: true

module Errbit
  class IssueTracker < ApplicationRecord
    belongs_to :app,
      class_name: "Errbit::App",
      foreign_key: :errbit_app_id,
      inverse_of: :issue_tracker,
      optional: true

    attribute :options, default: -> { {} }

    validate :validate_tracker

    def options
      super&.with_indifferent_access || ActiveSupport::HashWithIndifferentAccess.new
    end

    delegate :configured?, to: :tracker
    delegate :create_issue, to: :tracker
    delegate :close_issue, to: :tracker
    delegate :url, to: :tracker

    def type_tracker
      self[:type_tracker] || "none"
    end

    def tracker
      @tracker ||= begin
        klass = ErrbitPlugin::Registry.issue_trackers[type_tracker] || ErrbitPlugin::NoneIssueTracker
        klass.new(
          options.merge(
            github_repo: app.try(:github_repo),
            bitbucket_repo: app.try(:bitbucket_repo)
          )
        )
      end
    end

    def validate_tracker
      (tracker.errors || {}).each do |k, v|
        errors.add(k, v)
      end
    end
  end
end
