class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps
  include HashHelper
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]

  embedded_in :app, :inverse_of => :issue_tracker

  field :project_id, :type => String
  field :alt_project_id, :type => String # Specify an alternative project id. e.g. for viewing files
  field :api_token, :type => String
  field :account, :type => String
  field :username, :type => String
  field :password, :type => String
  field :ticket_properties, :type => String
  field :subdomain, :type => String
  field :milestone_id, :type => String

  validate :check_params

  # Subclasses are responsible for overwriting this method.
  def check_params; true; end

  def issue_title(problem)
    "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"
  end

  # Allows us to set the issue tracker class from a single form.
  def type; self._type; end
  def type=(t); self._type=t; end

  def url; nil; end

  # Retrieve tracker label from either class or instance.
  Label = ''
  def self.label; self::Label; end
  def label; self.class.label; end

  def configured?
    project_id.present?
  end

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
end
