require 'recurse'

class Notice < ActiveRecord::Base

  serialize :server_environment, Hash
  serialize :request, Hash
  serialize :notifier, Hash
  serialize :user_attributes, Hash
  serialize :current_user, Hash

  delegate :lines, :to => :backtrace, :prefix => true
  delegate :app, :problem, :to => :err

  belongs_to :err
  belongs_to :backtrace

  after_create :cache_attributes_on_problem, :unresolve_problem
  after_commit :email_notification, :services_notification, on: :create
  before_save :sanitize
  before_destroy :decrease_counter_cache, :remove_cached_attributes_from_problem
  after_initialize :default_values

  validates_presence_of :backtrace, :server_environment, :notifier

  scope :ordered, -> { reorder('created_at asc') }
  scope :reverse_ordered, -> { reorder('created_at desc') }
  scope :for_errs, lambda {|errs| where(:err_id => errs.pluck(:id))}
  scope :created_between, lambda {|start_date, end_date| where(created_at: start_date..end_date)}
  scope :after, lambda { |time| where(arel_table[:created_at].gteq(time)) }

  def default_values
    if self.new_record?
      self.server_environment ||= Hash.new
      self.request ||= Hash.new
      self.notifier ||= Hash.new
      self.user_attributes ||= Hash.new
      self.current_user ||= Hash.new
    end
  end

  def user_agent
    agent_string = env_vars['HTTP_USER_AGENT']
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
  end

  def user_agent_string
    if user_agent.nil? || user_agent.none?
      "N/A"
    else
      "#{user_agent.browser} #{user_agent.version} (#{user_agent.os})"
    end
  end

  def environment_name
    server_environment['server-environment'] || server_environment['environment-name']
  end

  def component
    request['component']
  end

  def action
    request['action']
  end

  def where
    where = component.to_s.dup
    where << "##{action}" if action.present?
    where
  end

  def request
    super || {}
  end

  def url
    request['url']
  end

  def host
    uri = url && URI.parse(url)
    uri.blank? ? "N/A" : uri.host
  rescue URI::InvalidURIError
    "N/A"
  end

  def env_vars
    request['cgi-data'] || {}
  end

  def params
    request['params'] || {}
  end

  def session
    request['session'] || {}
  end

  def in_app_backtrace_lines
    backtrace_lines.in_app
  end

  def similar_count
    problem.notices_since_reopened
  end

  def emailable?
    app.email_at_notices.include?(similar_count)
  end

  def should_email?
    app.emailable? && emailable?
  end

  def should_notify?
    app.notification_service.notify_at_notices.include?(0) || app.notification_service.notify_at_notices.include?(similar_count)
  end

  ##
  # TODO: Move on decorator maybe
  #
  def project_root
    if server_environment
      server_environment['project-root'] || ''
    end
  end

  def app_version
    if server_environment
      server_environment['app-version'] || ''
    end
  end
  
  def git_commit
    env_vars["GIT_COMMIT"]
  end

  protected

  def decrease_counter_cache
    problem.inc(:notices_count, -1) if err
  end

  def remove_cached_attributes_from_problem
    problem.remove_cached_notice_attributes(self) if err
  end

  def unresolve_problem
    return unless problem.resolved?
    problem.update_attributes!(resolved: false, resolved_at: nil, opened_at: created_at)
  end

  def cache_attributes_on_problem
    ProblemUpdaterCache.new(problem, self).update
  end

  def sanitize
    [:server_environment, :request, :notifier].each do |h|
      send("#{h}=",sanitize_hash(send(h)))
    end
  end


  def sanitize_hash(h)
    h.recurse do |h|
      h.inject({}) do |h,(k,v)|
        if k.is_a?(String)
          h[k.gsub(/\./,'&#46;').gsub(/^\$/,'&#36;')] = v
        else
          h[k] = v
        end
        h
      end
    end
  end

  private

  ##
  # Send email notification if needed
  def email_notification
    return true unless should_email?
    Mailer.err_notification(self).deliver
  rescue => e
    # Don't send a notice if we fail to send a notice
    # that we've failed to send a notice.
    # i.e. Don't make this an infinite loop.
    return if app.name == "Self.Errbit" &&
      backtrace.includes?("app/models/notice.rb#email_notification")
    HoptoadNotifier.notify(e)
  end

  ##
  # Launch all notification define on the app associate to this notice
  def services_notification
    return true unless app.notification_service_configured? and should_notify?
    app.notification_service.create_notification(problem)
  rescue => e
    # Don't send a notice if we fail to send a notice
    # that we've failed to send a notice.
    # i.e. Don't make this an infinite loop.
    return if app.name == "Self.Errbit" &&
      backtrace.includes?("app/models/notice.rb#services_notification")
    HoptoadNotifier.notify(e)
  end

end

