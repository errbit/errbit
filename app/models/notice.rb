require 'hoptoad'

class Notice
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :backtrace, :type => Array
  field :server_environment, :type => Hash
  field :request, :type => Hash
  field :notifier, :type => Hash
  
  embedded_in :error, :inverse_of => :notices
  
  def self.from_xml(hoptoad_xml)
    hoptoad_notice = Hoptoad::V2.parse_xml(hoptoad_xml)
    
    error = Error.for({
      :class_name => hoptoad_notice['error']['class'],
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