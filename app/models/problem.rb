# Represents a single Problem. The problem may have been
# reported as various Errs, but the user has grouped the
# Errs together as belonging to the same problem.

class Problem < ActiveRecord::Base
  acts_as_paranoid

  serialize :messages, Hash
  serialize :user_agents, Hash
  serialize :hosts, Hash

  belongs_to :app, inverse_of: :problems
  has_many :errs, inverse_of: :problem, dependent: :destroy
  has_many :comments, through: :errs

  validates_presence_of :environment

  before_create :cache_app_attributes
  after_initialize :default_values

  def self.resolved
    where(resolved: true)
  end

  def self.unresolved
    where(resolved: false)
  end

  def self.ordered
    order("last_notice_at desc")
  end

  def self.for_apps(apps)
    return where(app_id: apps.pluck(:id)) if apps.is_a? ActiveRecord::Relation
    where(app_id: apps.map(&:id))
  end

  validates_presence_of :last_notice_at, :first_notice_at, :opened_at

  def default_values
    if self.new_record?
      self.user_agents ||= Hash.new
      self.messages ||= Hash.new
      self.hosts ||= Hash.new
      self.comments_count ||= 0
      self.notices_count ||= 0
      self.resolved = false if self.resolved.nil?
      self.first_notice_at ||= Time.new
      self.last_notice_at ||= Time.new
      self.opened_at ||= 1.second.ago # Time.new
    end
  end

  def self.all_else_unresolved(fetch_all)
    if fetch_all
      all
    else
      where(resolved: false)
    end
  end

  def self.in_env(env)
    env.present? ? where(environment: env) : all
  end

  def notices
    Notice.for_errs(errs).ordered
  end

  def comments_allowed?
    Errbit::Config.allow_comments_with_issue_tracker || !app.issue_tracker_configured?
  end

  def resolve!
    self.update_attributes!(resolved: true, resolved_at: Time.now)
  end

  def unresolve!
    self.update_attributes!(resolved: false, resolved_at: nil)
  end

  def unresolved?
    !resolved?
  end


  def self.merge!(*problems)
    ProblemMerge.new(problems).merge
  end

  def merged?
    errs.length > 1
  end

  def unmerge!
    ProblemUnmerge.new(self).execute
  end


  def self.ordered_by(sort, order)
    case sort
    when "app";            order("app_name #{order}")
    when "message";        order("message #{order}")
    when "last_notice_at"; order("last_notice_at #{order}")
    when "last_deploy_at"; order("last_deploy_at #{order}")
    when "count";          order("notices_count #{order}")
    else raise("\"#{sort}\" is not a recognized sort")
    end
  end

  def self.in_date_range(date_range)
    where(["first_notice_at <= ? AND (resolved_at IS NULL OR resolved_at >= ?)", date_range.end, date_range.begin])
  end

  def self.changed_since(timestamp)
    where arel_table[:updated_at].gteq(timestamp)
  end

  def self.occurred_since(timestamp)
    where arel_table[:last_notice_at].gteq(timestamp)
  end


  def reset_cached_attributes
    ProblemUpdaterCache.new(self).update
  end

  def cache_app_attributes
    if app
      self.app_name = app.name
      self.last_deploy_at = if (last_deploy = app.deploys.where(environment: self.environment).last)
        last_deploy.created_at.utc
      end
      Problem.where(id: self).update_all(
        app_name: self.app_name,
        last_deploy_at: self.last_deploy_at
      )
    end
  end

  def remove_cached_notice_attributes(notice)
    update_attributes!(
      messages:    attribute_count_descrease(:messages, notice.message),
      hosts:       attribute_count_descrease(:hosts, notice.host),
      user_agents: attribute_count_descrease(:user_agents, notice.user_agent_string)
    )
  end

  def issue_type
    # Return issue_type if configured, but fall back to detecting app's issue tracker
    attributes['issue_type'] ||=
    (app.issue_tracker_configured? && app.issue_tracker.label) || nil
  end

  def inc(attr, increment_by)
    self.update_attribute(attr, self.send(attr) + increment_by)
  end

  def self.search(value)
    t = arel_table
    where(t[:error_class].matches("%#{value}%")
      .or(t[:where].matches("%#{value}%"))
      .or(t[:message].matches("%#{value}%"))
      .or(t[:app_name].matches("%#{value}%"))
      .or(t[:environment].matches("%#{value}%"))
    )
  end

  def to_param
    errs.first.to_param
  end

  def notices_since_reopened
    notices.after(opened_at).count
  end

  private

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
