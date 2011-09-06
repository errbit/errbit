# An Problem is a group of errs that the user
# has declared to be equal.

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :last_notice_at, :type => DateTime
  field :resolved, :type => Boolean, :default => false
  field :issue_link, :type => String
  
  # Cached fields
  field :notices_count, :type => Integer, :default => 0
  field :message
  field :environment
  field :klass
  field :where
  
  index :last_notice_at
  index :app_id
  
  belongs_to :app
  has_many :errs, :inverse_of => :problem, :dependent => :destroy
  has_many :comments, :inverse_of => :err, :dependent => :destroy
  
  scope :resolved, where(:resolved => true)
  scope :unresolved, where(:resolved => false)
  scope :ordered, order_by(:last_notice_at.desc)
  scope :for_apps, lambda {|apps| where(:app_id.in => apps.all.map(&:id))}
  
  def self.in_env(env)
    env.present? ? where(:environment => env) : scoped
  end
  
  
  
  def notices
    Notice.for_errs(errs).ordered
  end
  
  
  def resolve!
    self.update_attributes!(:resolved => true)
  end
  
  
  def unresolve!
    self.update_attributes!(:resolved => false)
  end
  
  
  def unresolved?
    !resolved?
  end
  
  
  
  def cache_notice_attributes(notice=nil)
    notice ||= notices.first
    attrs = {:last_notice_at => notices.max(:created_at)}
    attrs.merge!(
      :message => notice.message,
      :environment => notice.environment_name,
      :klass => notice.klass,
      :where => notice.where) if notice
    update_attributes!(attrs)
  end
  
  
end