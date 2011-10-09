require 'hoptoad'
require 'recurse'

class Notice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :message
  field :backtrace, :type => Array
  field :server_environment, :type => Hash
  field :request, :type => Hash
  field :notifier, :type => Hash
  field :klass

  belongs_to :err
  index :err_id
  index :created_at

  after_create :increase_counter_cache, :cache_attributes_on_problem, :unresolve_problem
  after_create :deliver_notification, :if => :should_notify?
  before_save :sanitize
  before_destroy :decrease_counter_cache

  validates_presence_of :backtrace, :server_environment, :notifier

  scope :ordered, order_by(:created_at.asc)
  scope :for_errs, lambda {|errs| where(:err_id.in => errs.all.map(&:id))}

  delegate :app, :problem, :to => :err

  def user_agent
    agent_string = env_vars['HTTP_USER_AGENT']
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
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

  def self.in_app_backtrace_line?(line)
    !!(line['file'] =~ %r{^\[PROJECT_ROOT\]/(?!(vendor))})
  end

  def request
    read_attribute(:request) || {}
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

  def deliver_notification
    Mailer.err_notification(self).deliver
  end

  # Backtrace containing only files from the app itself (ignore gems)
  def app_backtrace
    backtrace.select { |l| l && l['file'] && l['file'].include?("[PROJECT_ROOT]") }
  end

  protected

  def should_notify?
    app.notify_on_errs? && (Errbit::Config.per_app_email_at_notices && app.email_at_notices || Errbit::Config.email_at_notices).include?(problem.notices_count) && app.watchers.any?
  end

  def increase_counter_cache
    problem.inc(:notices_count, 1)
  end

  def decrease_counter_cache
    problem.inc(:notices_count, -1) if err
  end

  def unresolve_problem
    problem.update_attribute(:resolved, false) if problem.resolved?
  end


  def cache_attributes_on_problem
    problem.cache_notice_attributes(self)
  end

  def sanitize
    [:server_environment, :request, :notifier].each do |h|
      send("#{h}=",sanitize_hash(send(h)))
    end
    # Set unknown backtrace files
    backtrace.each{|line| line['file'] = "[unknown source]" if line['file'].blank? }
  end

  def sanitize_hash(h)
    h.recurse do
      |h| h.inject({}) do |h,(k,v)|
        if k.is_a?(String)
          h[k.gsub(/\./,'&#46;').gsub(/^\$/,'&#36;')] = v
        else
          h[k] = v
        end
        h
      end
    end
  end

end

