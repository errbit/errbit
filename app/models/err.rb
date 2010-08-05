class Err
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :klass
  field :message
  field :component
  field :action
  field :environment
  field :resolved, :type => Boolean, :default => false
  
  referenced_in :project
  embeds_many :notices
  
  validates_presence_of :klass, :environment
  
  scope :resolved, where(:resolved => true)
  scope :unresolved, where(:resolved => false)
  
  def self.for(attrs)
    project = attrs.delete(:project)
    project.errs.unresolved.where(attrs).first || project.errs.create!(attrs)
  end
  
  def resolve!
    self.update_attributes(:resolved => true)
  end
  
  def unresolved?
    !resolved?
  end
  
  def last_notice_at
    notices.last.try(:created_at)
  end
  
  def where
    where = component
    where << "##{action}" if action.present?
    where
  end
  
end