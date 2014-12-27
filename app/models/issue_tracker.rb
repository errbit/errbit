class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :app, :inverse_of => :issue_tracker

  field :type_tracker, :type => String
  field :options, :type => Hash, :default => {}

  validate :validate_tracker

  def tracker
    @tracker ||=
      begin
        klass = ErrbitPlugin::Registry.issue_trackers[self.type_tracker] || ErrbitPlugin::NoneIssueTracker
        klass.new(options.merge(github_repo: app.github_repo, bitbucket_repo: app.bitbucket_repo))
      end
  end

  # Allow the tracker to validate its own params
  def validate_tracker
    (tracker.errors || {}).each do |k,v|
      errors.add k, v
    end
  end

  delegate :configured?, :to => :tracker
  delegate :create_issue, :to => :tracker
  delegate :url, :to => :tracker
end
