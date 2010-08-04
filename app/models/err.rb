class Err
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :klass
  field :message
  field :component
  field :action
  field :environment
  field :resolved, :type => Boolean
  
  referenced_in :project
  embeds_many :notices
  
  validates_presence_of :klass, :environment
  
  def self.for(attrs)
    project = attrs.delete(:project)
    project.errs.where(attrs).first || project.errs.create(attrs)
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
  
end