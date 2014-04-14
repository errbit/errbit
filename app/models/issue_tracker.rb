class IssueTracker < ActiveRecord::Base

  include HashHelper
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
  default_url_options[:port] = ActionMailer::Base.default_url_options[:port]

  belongs_to :app, :inverse_of => :issue_tracker

  validate :check_params

  # Subclasses are responsible for overwriting this method.
  def check_params; true; end

  def issue_title(problem)
    "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"
  end

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

if Rails.env.development?
  Dir[Rails.root.join("app/models/issue_trackers/*.rb")].each { |file| require_dependency file }
end
