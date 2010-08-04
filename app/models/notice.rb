require 'hoptoad'

class Notice
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :backtrace, :type => Array
  field :server_environment, :type => Hash
  field :request, :type => Hash
  field :notifier, :type => Hash
  
  embedded_in :err, :inverse_of => :notices
  
  validates_presence_of :backtrace, :server_environment, :notifier
  
  def self.from_xml(hoptoad_xml)
    hoptoad_notice = Hoptoad::V2.parse_xml(hoptoad_xml)
    project = Project.find_by_api_key!(hoptoad_notice['api-key'])
    
    error = Err.for({
      :project    => project,
      :klass      => hoptoad_notice['error']['class'],
      :message    => hoptoad_notice['error']['message'],
      :component  => hoptoad_notice['request']['component'],
      :action     => hoptoad_notice['request']['action'],
      :environment  => hoptoad_notice['server-environment']['environment-name']
    })
    
    error.notices.create({
      :backtrace => hoptoad_notice['error']['backtrace']['line'],
      :server_environment => hoptoad_notice['server-environment'],
      :request => hoptoad_notice['request'],
      :notifier => hoptoad_notice['notifier']
    })
  end
  
end