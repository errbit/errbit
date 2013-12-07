class IssueTracker < ActiveRecord::Base

  include HashHelper
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
  default_url_options[:port] = ActionMailer::Base.default_url_options[:port]

  belongs_to :app, :inverse_of => :issue_tracker

  validate :check_params

  # Subclasses are responsible for overwriting this method.
  # FIXME: problem with AR & has_one, try resolve this through patch build_issue_tracker
  def check_params
    return true if type.blank?
    sti = type.constantize.new(self.attributes)
    sti.valid?
    sti.errors[:base].each {|msg| self.errors.add :base, msg}
  end

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
