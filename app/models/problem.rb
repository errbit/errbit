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
  
  
  
  def self.merge!(*problems)
    problems = problems.flatten.uniq
    merged_problem = problems.shift
    problems.each do |problem|
      merged_problem.errs.concat Err.where(:problem_id => problem.id)
      problem.errs(true) # reload problem.errs (should be empty) before problem.destroy
      problem.destroy
    end
    merged_problem.reset_cached_attributes
    merged_problem
  end
  
  def merged?
    errs.length > 1
  end
  
  def unmerge!
    [self] + errs[1..-1].map(&:id).map do |err_id|
      err = Err.find(err_id)
      app.problems.create.tap do |new_problem|
        err.update_attribute(:problem_id, new_problem.id)
        new_problem.reset_cached_attributes
      end
    end
  end
  
  
  
  def reset_cached_attributes
    update_attribute(:notices_count, notices.count)
    cache_notice_attributes
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