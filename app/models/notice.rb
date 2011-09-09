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

  belongs_to :err
  index :err_id

  after_create :cache_last_notice_at
  after_create :deliver_notification, :if => :should_notify?
  before_create :increase_counter_cache, :cache_message
  before_save :sanitize
  before_destroy :decrease_counter_cache

  validates_presence_of :backtrace, :server_environment, :notifier

  scope :ordered, order_by(:created_at.asc)
  index :created_at

  def self.from_xml(hoptoad_xml)
    hoptoad_notice = Hoptoad::V2.parse_xml(hoptoad_xml)
    app = App.find_by_api_key!(hoptoad_notice['api-key'])

    hoptoad_notice['request'] ||= {}
    hoptoad_notice['request']['component']  = 'unknown' if hoptoad_notice['request']['component'].blank?
    hoptoad_notice['request']['action']     = nil if hoptoad_notice['request']['action'].blank?

    err = Err.for({
      :app      => app,
      :klass        => hoptoad_notice['error']['class'],
      :component    => hoptoad_notice['request']['component'],
      :action       => hoptoad_notice['request']['action'],
      :environment  => hoptoad_notice['server-environment']['environment-name'],
      :fingerprint  => hoptoad_notice['fingerprint']
    })
    err.update_attributes(:resolved => false) if err.resolved?

    err.notices.create!({
      :message            => hoptoad_notice['error']['message'],
      :backtrace          => [hoptoad_notice['error']['backtrace']['line']].flatten,
      :server_environment => hoptoad_notice['server-environment'],
      :request            => hoptoad_notice['request'],
      :notifier           => hoptoad_notice['notifier']
    })
  end

  def user_agent
    agent_string = env_vars['HTTP_USER_AGENT']
    agent_string.blank? ? nil : UserAgent.parse(agent_string)
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

  def cache_last_notice_at
    err.update_attributes(:last_notice_at => created_at)
  end

  # Backtrace containing only files from the app itself (ignore gems)
  def app_backtrace
    backtrace.select { |l| l && l['file'] && l['file'].include?("[PROJECT_ROOT]") }
  end

  protected

  def should_notify?
    err.app.notify_on_errs? && (Errbit::Config.per_app_email_at_notices && err.app.email_at_notices || Errbit::Config.email_at_notices).include?(err.notices.count) && err.app.watchers.any?
  end


  def increase_counter_cache
    err.inc(:notices_count,1)
  end

  def decrease_counter_cache
    err.inc(:notices_count,-1)
  end

  def cache_message
    err.update_attribute(:message, message) if err.notices_count == 1
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

