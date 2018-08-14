# Represents a single Problem. The problem may have been
# reported as various Errs, but the user has grouped the
# Errs together as belonging to the same problem.

# rubocop:disable Metrics/ClassLength. At some point we need to break up this class, but I think it doesn't have to be right now.
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
  scope :search, ->(value) { where('$text' => { '$search' => value }) }

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

  def self.filtered(filter)
    if filter
      filter_components = filter.scan(/(-app):(['"][^'"]+['"]|[^ ]+)/)
      app_names_to_exclude = filter_components.map do |filter_component_tuple|
        filter_type, filter_value = filter_component_tuple

        # get rid of quotes that we pulled in from the regex matcher above
        filter_value.gsub!(/^['"]/, '')
        filter_value.gsub!(/['"]$/, '')

        # this is the only supported filter_type at this time
        if filter_type == '-app'
          filter_value
        end
      end
    end

    if filter && app_names_to_exclude.present?
      where(:app_name.nin => app_names_to_exclude)
    else
      scoped
    end
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
      host:     Errbit::Config.host,
      port:     Errbit::Config.port
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

  def grouped_notice_counts(since, group_by = 'day')
    key_op = [['year', '$year'], ['day', '$dayOfYear'], ['hour', '$hour']]
    key_op = key_op.take(1 + key_op.find_index { |key, _op| group_by == key })
    project_date_fields = Hash[*key_op.collect { |key, op| [key, { op => "$created_at" }] }.flatten]
    group_id_fields = Hash[*key_op.collect { |key, _op| [key, "$#{key}"] }.flatten]
    pipeline = [
      {
        "$match" => {
          "err_id"     => { '$in' => errs.map(&:id) },
          "created_at" => { "$gt" => since }
        }
      },
      { "$project" => project_date_fields },
      { "$group" => { "_id" => group_id_fields, "count" => { "$sum" => 1 } } },
      { "$sort" => { "_id" => 1 } }
    ]
    Notice.collection.aggregate(pipeline).find.to_a
  end

  def zero_filled_grouped_noticed_counts(since, group_by = 'day')
    non_zero_filled = grouped_notice_counts(since, group_by)
    buckets = group_by == 'day' ? 14 : 24

    ruby_time_method = group_by == 'day' ? :yday : :hour
    bucket_times = Array.new(buckets) { |ii| (since + ii.send(group_by)).send(ruby_time_method) }
    bucket_times.to_a.map do |bucket_time|
      count = if (data_for_day = non_zero_filled.detect { |item| item.dig('_id', group_by) == bucket_time })
                data_for_day['count']
              else
                0
              end
      { bucket_time => count }
    end
  end

  def grouped_notice_count_relative_percentages(since, group_by = 'day')
    zero_filled = zero_filled_grouped_noticed_counts(since, group_by).map { |h| h.values.first }
    max = zero_filled.max
    zero_filled.map do |number|
      max.zero? ? 0 : number.to_f / max.to_f * 100.0
    end
  end

  def self.ordered_by(sort, order)
    case sort
    when "app"            then order_by(["app_name", order])
    when "environment"    then order_by(["environment", order])
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

private

  def attribute_count_decrease(name, value)
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
# rubocop:enable Metrics/ClassLength
