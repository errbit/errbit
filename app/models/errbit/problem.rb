# frozen_string_literal: true

module Errbit
  class Problem < ApplicationRecord
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

    def cache_app_attributes
      self.app_name = app.name if app
    end
  end
end
