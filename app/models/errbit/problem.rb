# frozen_string_literal: true

module Errbit
  class Problem < ApplicationRecord
    # Routes (`resources :problems`, nested under apps), form helpers, partial
    # paths, and i18n scopes still use the un-namespaced "problem" key.
    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "Problem")
    end

    CACHED_NOTICE_ATTRIBUTES = {
      messages: :message,
      hosts: :host,
      user_agents: :user_agent_string
    }.freeze

    belongs_to :app,
      class_name: "Errbit::App",
      foreign_key: :errbit_app_id,
      inverse_of: :problems

    has_many :errs,
      class_name: "Errbit::Err",
      foreign_key: :errbit_problem_id,
      inverse_of: :problem,
      dependent: :destroy

    has_many :comments,
      class_name: "Errbit::Comment",
      foreign_key: :errbit_problem_id,
      inverse_of: :err,
      dependent: :destroy

    attribute :first_notice_at, default: -> { Time.zone.now }
    attribute :last_notice_at, default: -> { Time.zone.now }
    attribute :user_agents, default: -> { {} }
    attribute :messages, default: -> { {} }
    attribute :hosts, default: -> { {} }

    validates :environment, presence: true
    validates :first_notice_at, presence: true
    validates :last_notice_at, presence: true

    before_create :cache_app_attributes

    scope :resolved, -> { where(resolved: true) }
    scope :unresolved, -> { where(resolved: false) }
    scope :ordered, -> { order(last_notice_at: :desc) }
    scope :for_apps, ->(apps) { where(errbit_app_id: apps.map(&:id)) }

    # If `value` matches an existing notice id, return that notice's problem.
    # Otherwise LIKE-search the cached text columns. Mirrors the Mongoid
    # `$text` scope while staying within plain SQL.
    scope :search, lambda { |value|
      notice = Errbit::Notice.where(id: value).first
      next where(id: notice.err.errbit_problem_id) if notice

      pattern = "%#{value}%"
      where(
        arel_table[:error_class].matches(pattern)
          .or(arel_table[:message].matches(pattern))
          .or(arel_table[:app_name].matches(pattern))
          .or(arel_table[:environment].matches(pattern))
          .or(arel_table[:where].matches(pattern))
      )
    }

    def self.all_else_unresolved(fetch_all)
      fetch_all ? all : where(resolved: false)
    end

    def self.in_env(env)
      env.present? ? where(environment: env) : all
    end

    def self.filtered(filter)
      app_names_to_exclude = []

      if filter
        filter.scan(/(-app):(['"][^'"]+['"]|[^ ]+)/).each do |filter_type, filter_value|
          filter_value = filter_value.gsub(/^['"]/, "").gsub(/['"]$/, "")
          app_names_to_exclude << filter_value if filter_type == "-app"
        end
      end

      app_names_to_exclude.present? ? where.not(app_name: app_names_to_exclude) : all
    end

    def self.ordered_by(sort, order)
      column = case sort
      when "app" then :app_name
      when "environment" then :environment
      when "message" then :message
      when "last_notice_at" then :last_notice_at
      when "count" then :notices_count
      else
        fail("\"#{sort}\" is not a recognized sort")
      end

      order(column => order)
    end

    def url
      Rails.application.routes.url_helpers.app_problem_url(
        app, self, host: Errbit::Config.host
      )
    end

    def notices
      Errbit::Notice.for_errs(errs).ordered
    end

    def recache
      notice_records = notices.to_a

      CACHED_NOTICE_ATTRIBUTES.each do |attr, source|
        counts = Hash.new(0)
        values = {}

        notice_records.each do |notice|
          value = notice.send(source) || "N/A"
          key = Digest::MD5.hexdigest(value)
          counts[key] += 1
          values[key] = value
        end

        hash = counts.each_with_object({}) do |(key, count), h|
          h[key] = {"value" => values[key], "count" => count}
        end

        send(:"#{attr}=", hash)
      end

      first_notice = notice_records.min_by(&:created_at)
      last_notice = notice_records.max_by(&:created_at)

      self.notices_count = notice_records.size
      if first_notice
        self.first_notice_at = first_notice.created_at
        self.message = first_notice.message
        self.where = first_notice.where
      end
      self.last_notice_at = last_notice.created_at if last_notice

      save
    end

    def resolve!
      update!(resolved: true, resolved_at: Time.zone.now)
    end

    def unresolve!
      update!(resolved: false, resolved_at: nil)
    end

    def unresolved?
      !resolved?
    end

    def link_text
      message.presence || error_class
    end

    # Override the column reader: when the stored value is nil, fall back to
    # the app's configured issue tracker type. Cached into the in-memory
    # attribute (Mongoid behavior) without persisting.
    def issue_type
      self[:issue_type] ||= (app.issue_tracker_configured? && app.issue_tracker.type_tracker) || nil
    end

    def self.merge!(*problems)
      result = Errbit::ProblemMerge.new(problems).merge
      result.reload
    end

    # Apply a freshly-received notice to the problem's cached fields:
    # latest environment/error_class/message/where/last_notice_at, the
    # resolved-flag reset, the messages/hosts/user_agents digest counters,
    # and notices_count++. Mirrors the Mongoid `cache_notice` atomic upsert
    # in a single `UPDATE` via `save!`.
    def self.cache_notice(id, notice)
      problem = find(id)

      problem.update!(
        environment: notice.environment_name,
        error_class: notice.error_class,
        last_notice_at: notice.created_at.utc,
        message: notice.message,
        resolved: false,
        resolved_at: nil,
        where: notice.where,
        notices_count: (problem.notices_count || 0) + 1,
        messages: increment_hash_counter(problem.messages, Digest::MD5.hexdigest(notice.message.to_s), notice.message),
        hosts: increment_hash_counter(problem.hosts, Digest::MD5.hexdigest(notice.host.to_s), notice.host),
        user_agents: increment_hash_counter(problem.user_agents, Digest::MD5.hexdigest(notice.user_agent_string.to_s), notice.user_agent_string)
      )

      problem
    end

    def self.increment_hash_counter(hash, key, value)
      result = (hash || {}).deep_dup
      result[key] ||= {"value" => value, "count" => 0}
      result[key]["value"] = value
      result[key]["count"] += 1
      result
    end
    private_class_method :increment_hash_counter

    # Counterpart to `cache_notice`: when a notice is destroyed, refresh the
    # problem's cached fields from the most recent remaining notice and
    # decrement the matching hash counter (or drop the digest entry entirely).
    def uncache_notice(notice)
      last_notice = notices.reorder(created_at: :desc).first
      return unless last_notice

      attrs = {
        environment: last_notice.environment_name,
        error_class: last_notice.error_class,
        last_notice_at: last_notice.created_at,
        message: last_notice.message,
        where: last_notice.where,
        notices_count: (notices_count.to_i > 1) ? notices_count - 1 : 0
      }

      CACHED_NOTICE_ATTRIBUTES.each do |attr, source|
        attrs[attr] = decrement_hash_counter(send(attr), Digest::MD5.hexdigest(notice.send(source).to_s))
      end

      update!(attrs)
    end

    private

    def decrement_hash_counter(hash, key)
      result = (hash || {}).deep_dup

      if result[key] && result[key]["count"].to_i > 1
        result[key]["count"] -= 1
      else
        result.delete(key)
      end

      result
    end

    public

    def merged?
      errs.length > 1
    end

    def unmerge!
      attrs = {error_class: error_class, environment: environment}
      problem_errs = errs.to_a

      new_problems = [self]
      (problem_errs[1..] || []).each do |err|
        new_problems << app.problems.create(attrs)
        err.update!(problem: new_problems.last)
      end

      errs.reset
      new_problems.each(&:recache)
      new_problems
    end

    def cache_app_attributes
      self.app_name = app.name if app
    end

    # Bucketed notice counts since the given moment, grouped by `:yday` or
    # `:hour`. Returns the Mongoid-shaped output [{"_id" => {group_by => bucket},
    # "count" => n}, ...]. Used by `xhr_sparkline`.
    def grouped_notice_counts(since, group_by = "day")
      time_method = (group_by == "day") ? :yday : :hour

      Errbit::Notice
        .for_errs(errs)
        .where("created_at > ?", since)
        .pluck(:created_at)
        .group_by { |t| t.send(time_method) }
        .map { |bucket, ts| {"_id" => {group_by => bucket}, "count" => ts.size} }
        .sort_by { |row| row["_id"][group_by] }
    end

    def zero_filled_grouped_noticed_counts(since, group_by = "day")
      non_zero_filled = grouped_notice_counts(since, group_by)
      buckets = (group_by == "day") ? 14 : 24
      time_method = (group_by == "day") ? :yday : :hour

      bucket_times = Array.new(buckets) { |i| (since + i.send(group_by)).send(time_method) }
      bucket_times.map do |bucket_time|
        match = non_zero_filled.detect { |row| row.dig("_id", group_by) == bucket_time }
        {bucket_time => match ? match["count"] : 0}
      end
    end

    def grouped_notice_count_relative_percentages(since, group_by = "day")
      counts = zero_filled_grouped_noticed_counts(since, group_by).map { |h| h.values.first }
      max = counts.max
      counts.map { |n| max.zero? ? 0 : (n.to_f / max.to_f) * 100.0 }
    end
  end
end
