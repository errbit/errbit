# Represents a single Problem. The problem may have been
# reported as various Errs, but the user has grouped the
# Errs together as belonging to the same problem.

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps

  CACHED_NOTICE_ATTRIBUTES = {
    messages:    :message,
    hosts:       :host,
    user_agents: :user_agent_string
  }.freeze

  field :last_notice_at, type: ActiveSupport::TimeWithZone, default: proc { Time.zone.now }
  field :first_notice_at, type: ActiveSupport::TimeWithZone, default: proc { Time.zone.now }
  field :resolved, type: Boolean, default: false
  field :resolved_at, type: Time
  field :issue_link, type: String
  field :issue_type, type: String

  # Cached fields
  field :app_name, type: String
  field :notices_count, type: Integer, default: 0
  field :message
  field :environment
  field :error_class
  field :where
  field :user_agents, type: Hash, default: {}
  field :messages,    type: Hash, default: {}
  field :hosts,       type: Hash, default: {}
  field :comments_count, type: Integer, default: 0

  index app_id: 1
  index app_name: 1
  index message: 1
  index last_notice_at: 1
  index first_notice_at: 1
  index resolved_at: 1
  index notices_count: 1

  index({
    error_class: "text",
    where:       "text",
    message:     "text",
    app_name:    "text",
    environment: "text"
  }, default_language: "english")

  belongs_to :app
  has_many :errs, inverse_of: :problem, dependent: :destroy
  has_many :comments, inverse_of: :err, dependent: :destroy

  validates :environment, presence: true
  validates :last_notice_at, :first_notice_at, presence: true

  before_create :cache_app_attributes

  scope :resolved, -> { where(resolved: true) }
  scope :unresolved, -> { where(resolved: false) }
  scope :ordered, -> { order_by(:last_notice_at.desc) }
  scope :for_apps, ->(apps) { where(:app_id.in => apps.all.map(&:id)) }

  def self.all_else_unresolved(fetch_all)
    if fetch_all
      all
    else
      where(resolved: false)
    end
  end

  def self.in_env(env)
    env.present? ? where(environment: env) : scoped
  end

  def self.cache_notice(id, notice)
    # increment notice count
    message_digest = Digest::MD5.hexdigest(notice.message)
    host_digest = Digest::MD5.hexdigest(notice.host)
    user_agent_digest = Digest::MD5.hexdigest(notice.user_agent_string)

    Problem.where('_id' => id).find_one_and_update({
      '$set' => {
        'environment'                            => notice.environment_name,
        'error_class'                            => notice.error_class,
        'last_notice_at'                         => notice.created_at.utc,
        'message'                                => notice.message,
        'resolved'                               => false,
        'resolved_at'                            => nil,
        'where'                                  => notice.where,
        "messages.#{message_digest}.value"       => notice.message,
        "hosts.#{host_digest}.value"             => notice.host,
        "user_agents.#{user_agent_digest}.value" => notice.user_agent_string
      },
      '$inc' => {
        'notices_count'                          => 1,
        "messages.#{message_digest}.count"       => 1,
        "hosts.#{host_digest}.count"             => 1,
        "user_agents.#{user_agent_digest}.count" => 1
      }
    }, return_document: :after)
  end

  def uncache_notice(notice)
    last_notice = notices.last

    atomically do |doc|
      doc.set(
        'environment'    => last_notice.environment_name,
        'error_class'    => last_notice.error_class,
        'last_notice_at' => last_notice.created_at,
        'message'        => last_notice.message,
        'where'          => last_notice.where,
        'notices_count'  => notices_count.to_i > 1 ? notices_count - 1 : 0
      )

      CACHED_NOTICE_ATTRIBUTES.each do |k, v|
        digest = Digest::MD5.hexdigest(notice.send(v))
        field = "#{k}.#{digest}"

        if (doc[k].try(:[], digest).try(:[], :count)).to_i > 1
          doc.inc("#{field}.count" => -1)
        else
          doc.unset(field)
        end
      end
    end
  end

  def recache
    CACHED_NOTICE_ATTRIBUTES.each do |k, v|
      # clear all cached attributes
      send("#{k}=", {})

      # find only notices related to this problem
      Notice.collection.find.aggregate([
        { "$match" => { err_id: { "$in" => err_ids } } },
        { "$group" => { _id: "$#{v}", count: { "$sum" => 1 } } }
      ]).each do |agg|
        send(k)[Digest::MD5.hexdigest(agg[:_id] || 'N/A')] = {
          'value' => agg[:_id] || 'N/A',
          'count' => agg[:count]
        }
      end
    end

    first_notice = notices.order_by([:created_at, :asc]).first
    last_notice = notices.order_by([:created_at, :desc]).first

    self.notices_count = notices.count
    self.first_notice_at = first_notice.created_at if first_notice
    self.message = first_notice.message if first_notice
    self.where = first_notice.where if first_notice
    self.last_notice_at = last_notice.created_at if last_notice

    save
  end

  def url
    Rails.application.routes.url_helpers.app_problem_url(
      app,
      self,
      protocol: Errbit::Config.protocol,
      host: Errbit::Config.host,
      port: Errbit::Config.port
    )
  end

  def notices
    Notice.for_errs(errs).ordered
  end

  def resolve!
    self.update_attributes!(resolved: true, resolved_at: Time.zone.now)
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
    attrs = { error_class: error_class, environment: environment }
    problem_errs = errs.to_a

    # associate and return all the problems
    new_problems = [self]

    # create new problems for each err that needs one
    (problem_errs[1..-1] || []).each do |err|
      new_problems << app.problems.create(attrs)
      err.update_attribute(:problem, new_problems.last)
    end

    # recache each new problem
    new_problems.each(&:recache)

    new_problems
  end

  def self.ordered_by(sort, order)
    case sort
    when "app"            then order_by(["app_name", order])
    when "message"        then order_by(["message", order])
    when "last_notice_at" then order_by(["last_notice_at", order])
    when "count"          then order_by(["notices_count", order])
    else fail("\"#{sort}\" is not a recognized sort")
    end
  end

  def cache_app_attributes
    self.app_name = app.name if app
  end

  def issue_type
    # Return issue_type if configured, but fall back to detecting app's issue tracker
    attributes['issue_type'] ||=
    (app.issue_tracker_configured? && app.issue_tracker.type_tracker) || nil
  end

  def self.search(value)
    Problem.where('$text' => { '$search' => value })
  end

private

  def attribute_count_descrease(name, value)
    counter = send(name)
    index = attribute_index(value)
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
