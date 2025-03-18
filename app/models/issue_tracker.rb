# frozen_string_literal: true

class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :app, inverse_of: :issue_tracker

  field :type_tracker, type: String
  field :options, type: Hash, default: {}

  validate :validate_tracker

  def tracker
    @tracker ||=
      begin
        klass = ErrbitPlugin::Registry.issue_trackers[type_tracker] || ErrbitPlugin::NoneIssueTracker
        # TODO: we need to find out a better way to pass those config to the issue tracker
        klass.new(
          options.merge(
            github_repo: app.try(:github_repo),
            bitbucket_repo: app.try(:bitbucket_repo)
          )
        )
      end
  end

  def type_tracker
    attributes["type_tracker"] || "none"
  end

  # Allow the tracker to validate its own params
  def validate_tracker
    (tracker.errors || {}).each do |k, v|
      errors.add k, v
    end
  end

  delegate :configured?, to: :tracker
  delegate :create_issue, to: :tracker
  delegate :close_issue, to: :tracker
  delegate :url, to: :tracker
end
