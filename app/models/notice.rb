require 'hoptoad'

class Notice
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :message
  field :backtrace, :type => Array
  field :server_environment, :type => Hash
  field :request, :type => Hash
  field :notifier, :type => Hash
  
  embedded_in :err, :inverse_of => :notices
  
  after_create :cache_last_notice_at
  after_create :deliver_notification, :if => :should_notify?
  
  validates_presence_of :backtrace, :server_environment, :notifier
  
  scope :ordered, order_by(:created_at.asc)
  
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
      :backtrace          => hoptoad_notice['error']['backtrace']['line'],
      :server_environment => hoptoad_notice['server-environment'],
      :request            => hoptoad_notice['request'],
      :notifier           => hoptoad_notice['notifier']
    })
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
  
  protected
  
    def should_notify?
      Errbit::Config.email_at_notices.include?(err.notices.count) && err.app.watchers.any?
    end
  
end