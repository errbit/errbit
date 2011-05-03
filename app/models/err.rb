class Err
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :klass
  field :component
  field :action
  field :environment
  field :fingerprint
  
  embedded_in :problem, :inverse_of => :errs
  embeds_many :notices
  
  validates_presence_of :klass, :environment
  
  delegate :app, :resolved?, :to => :problem
  
  
  def message
    notices.first.try(:message) || klass
  end
  
  
  def where
    where = component.dup
    where << "##{action}" if action.present?
    where
  end
  
  
end