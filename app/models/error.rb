class Error
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :klass
  field :message
  field :component
  field :action
  field :environment
  
  embeds_many :notices
  
  validates_presence_of :klass, :environment
  
  def self.for(attrs)
    self.where(attrs).first || create(attrs)
  end
  
  def last_notice_at
    notices.last.try(:created_at)
  end
  
end