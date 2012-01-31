# Represents a single Problem. The problem may have been
# reported as various Errs, but the user has grouped the
# Errs together as belonging to the same problem.

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :last_notice_at, :type => DateTime
  field :last_deploy_at, :type => Time
  field :resolved, :type => Boolean, :default => false
  field :issue_link, :type => String

  # Cached fields
  field :app_name, :type => String
  field :notices_count, :type => Integer, :default => 0
  field :message
  field :environment
  field :klass
  field :where
  field :user_agents, :type => Hash, :default => {}
  field :messages,    :type => Hash, :default => {}
  field :hosts,       :type => Hash, :default => {}
  field :comments_count, :type => Integer, :default => 0

  index :app_id
  index :app_name
  index :message
  index :last_notice_at
  index :last_deploy_at
  index :notices_count

  belongs_to :app
  has_many :errs, :inverse_of => :problem, :dependent => :destroy
  has_many :comments, :inverse_of => :err, :dependent => :destroy

  before_create :cache_app_attributes

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
    self.update_attributes!(:resolved => true, :notices_count => 0)
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
    problem_errs = errs.to_a
    problem_errs.shift
    [self] + problem_errs.map(&:id).map do |err_id|
      err = Err.find(err_id)
      app.problems.create.tap do |new_problem|
        err.update_attribute(:problem_id, new_problem.id)
        new_problem.reset_cached_attributes
      end
    end
  end


  def self.ordered_by(sort, order)
    case sort
    when "app";            order_by(["app_name", order])
    when "message";        order_by(["message", order])
    when "last_notice_at"; order_by(["last_notice_at", order])
    when "last_deploy_at"; order_by(["last_deploy_at", order])
    when "count";          order_by(["notices_count", order])
    else raise("\"#{sort}\" is not a recognized sort")
    end
  end


  def reset_cached_attributes
    update_attribute(:notices_count, notices.count)
    cache_app_attributes
    cache_notice_attributes
  end

  def cache_app_attributes
    if app
      self.app_name = app.name
      self.last_deploy_at = if (last_deploy = app.deploys.where(:environment => self.environment).last)
        last_deploy.created_at.utc
      end
      collection.update({'_id' => self.id},
                        {'$set' => {'app_name' => self.app_name,
                          'last_deploy_at' => self.last_deploy_at}})
    end
  end

  def cache_notice_attributes(notice=nil)
    notice ||= notices.first
    attrs = {:last_notice_at => notices.order_by([:created_at, :asc]).last.try(:created_at)}
    attrs.merge!(
      :message => notice.message,
      :environment => notice.environment_name,
      :klass => notice.klass,
      :where => notice.where,
      :messages    => attribute_count_increase(:messages, notice.message),
      :hosts       => attribute_count_increase(:hosts, notice.host),
      :user_agents => attribute_count_increase(:user_agents, notice.user_agent_string)
      ) if notice
    update_attributes!(attrs)
  end

  def remove_cached_notice_attribures(notice)
    update_attributes!(
      :messages    => attribute_count_descrease(:messages, notice.message),
      :hosts       => attribute_count_descrease(:hosts, notice.host),
      :user_agents => attribute_count_descrease(:user_agents, notice.user_agent_string)
    )
  end

  private
    def attribute_count_increase(name, value)
      counter, index = send(name), attribute_index(value)
      if counter[index].nil?
        counter[index] = {'value' => value, 'count' => 1}
      else
        counter[index]['count'] += 1
      end
      counter
    end

    def attribute_count_descrease(name, value)
      counter, index = send(name), attribute_index(value)
      if counter[index] && counter[index]['count'] > 1
        counter[index]['count'] -= 1
      else
        counter.delete(index)
      end
      counter
    end

    def attribute_index(value)
      Digest::MD5.hexdigest(value.to_s)
    end

end

