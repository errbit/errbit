class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :last_notice_at, :type => DateTime
  field :resolved, :type => Boolean, :default => false
  field :issue_link, :type => String
  field :notices_count, :type => Integer, :default => 0
  field :message
  
  index :last_notice_at
  index :app_id
  
  belongs_to :app
  embeds_many :errs
  has_many :comments, :inverse_of => :err, :dependent => :destroy
  
  scope :resolved, where(:resolved => true)
  scope :unresolved, where(:resolved => false)
  scope :ordered, order_by(:last_notice_at.desc)
  scope :in_env, lambda {|env| where('errs.environment' => env)}
  scope :for_apps, lambda {|apps| where(:app_id.in => apps.all.map(&:id))}
  
  delegate :environment, :klass, :where, :message, :to => :first_err
  
  
  def first_err
    errs.first
  end
  
  
  def self.merge!(*problems)
    problems = (problems.first.is_a?(Array) ? problems.first : problems).dup
    merged_problem = problems.shift
    problems.each do |problem|
      problem.errs.each {|err| merged_problem.errs << err.dup}
      problem.destroy
    end
    merged_problem
  end
  
  
  def merged?
    errs.length > 1
  end
  
  
  def unmerge!
    problems = [self]
    errs[1..-1].each do |err|
      new_problem = app.problems.create!
      new_problem.errs << err.dup
      problems << new_problem
      err.destroy
    end
    problems
  end
  
  
  # !todo: order
  def notices
    errs.inject([]) {|all, err| all + err.notices.ordered}
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
  
  
end