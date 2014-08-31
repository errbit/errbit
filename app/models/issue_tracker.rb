class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  include Rails.application.routes.url_helpers

  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
  default_url_options[:port] = ActionMailer::Base.default_url_options[:port]

  embedded_in :app, :inverse_of => :issue_tracker

  field :type_tracker, :type => String
  field :options, :type => Hash, :default => {}

  validate :validate_tracker

  ##
  # Update default_url_option with valid data from the request information
  #
  # @param [ Request ] a request with host, port and protocol
  #
  def self.update_url_options(request)
    IssueTracker.default_url_options[:host] = request.host
    IssueTracker.default_url_options[:port] = request.port
    IssueTracker.default_url_options[:protocol] = request.scheme
  end

  def tracker
    klass = ErrbitPlugin::Registry.issue_trackers[self.type_tracker]
    klass = ErrbitPlugin::NoneIssueTracker unless klass

    @tracker = klass.new(app, self.options)
  end

  # Allow the tracker to validate its own params
  def validate_tracker
    (tracker.errors || {}).each do |k,v|
      errors.add k, v
    end
  end

  delegate :configured?, :to => :tracker
  delegate :create_issue, :to => :tracker
  delegate :comments_allowed?, :to => :tracker
  delegate :url, :to => :tracker
end
