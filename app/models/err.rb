class Err
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :klass
  field :component
  field :action
  field :environment
  field :fingerprint
  field :last_notice_at, :type => DateTime
  field :resolved, :type => Boolean, :default => false
  
  referenced_in :project
  embeds_many :notices
  
  validates_presence_of :klass, :environment
  
  scope :resolved, where(:resolved => true)
  scope :unresolved, where(:resolved => false)
  scope :ordered, order_by(:last_notice_at.desc)
  
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
  
  def where
    where = component.dup
    where << "##{action}" if action.present?
    where
  end
  
  def message
    notices.first.message || klass
  end
  
end