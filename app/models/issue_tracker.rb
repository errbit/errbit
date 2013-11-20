class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  include Rails.application.routes.url_helpers

  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]

  embedded_in :app, :inverse_of => :issue_tracker

  field :type_tracker, :type => String
  field :options, :type => Hash, :default => {}

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
    @tracker ||= ErrbitPlugin::Register.issue_tracker(self.type_tracker).new(app, self.options)
  rescue NameError
    ErrbitPlugin::NoneIssueTracker.new(app, {})
  end
  delegate :configured?, :to => :tracker
  delegate :create_issue, :to => :tracker
  delegate :label, :to => :tracker
  delegate :comments_allowed?, :to => :tracker
end
