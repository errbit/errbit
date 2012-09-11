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
  field :user_attributes, :type => Hash
  field :current_user, :type => Hash
  field :error_class

  belongs_to :err
  index :created_at
  index(
    [
      [ :err_id, Mongo::ASCENDING ],
      [ :created_at, Mongo::ASCENDING ],
      [ :_id, Mongo::ASCENDING ]
    ]
  )

  after_create :increase_counter_cache, :cache_attributes_on_problem, :unresolve_problem
  before_save :sanitize
  before_destroy :decrease_counter_cache, :remove_cached_attributes_from_problem

  validates_presence_of :backtrace, :server_environment, :notifier

  scope :ordered, order_by(:created_at.asc)
  scope :reverse_ordered, order_by(:created_at.desc)
  scope :for_errs, lambda {|errs| where(:err_id.in => errs.all.map(&:id))}

  delegate :app, :problem, :to => :err

  def user_agent
    agent_string = env_vars['HTTP_USER_AGENT']
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
  end

  def user_agent_string
    (user_agent.nil? || user_agent.none?) ? "N/A" : "#{user_agent.browser} #{user_agent.version}"
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
    read_attribute(:request) || {}
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

  # Backtrace containing only files from the app itself (ignore gems)
  def app_backtrace
    backtrace.select { |l| l && l['file'] && l['file'].include?("[PROJECT_ROOT]") }
  end

  def backtrace
    # If gems are vendored into project, treat vendored gem dir as [GEM_ROOT]
    (read_attribute(:backtrace) || []).map do |line|
      # Changes "[PROJECT_ROOT]/rubygems/ruby/1.9.1/gems" to "[GEM_ROOT]/gems"
      line.merge 'file' => line['file'].to_s.gsub(/\[PROJECT_ROOT\]\/.*\/ruby\/[0-9.]+\/gems/, '[GEM_ROOT]/gems')
    end
  end

  protected

  def increase_counter_cache
    problem.inc(:notices_count, 1)
  end

  def decrease_counter_cache
    problem.inc(:notices_count, -1) if err
  end

  def remove_cached_attributes_from_problem
    problem.remove_cached_notice_attribures(self) if err
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
    read_attribute(:backtrace).each{|line| line['file'] = "[unknown source]" if line['file'].blank? }
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

