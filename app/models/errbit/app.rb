# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
    include Comparable

    # Routes (`resources :apps`), form helpers (`form_with model: app`), Pundit
    # `param_key`, partial paths, and i18n scopes all live under the un-namespaced
    # "app" key. Override `model_name` so they match even though the class is
    # under `Errbit::`.
    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "App")
    end

    # Pundit infers the policy class via model_name → "AppPolicy" (Mongoid).
    # Force it back to the namespaced policy.
    def self.policy_class
      Errbit::AppPolicy
    end

    serialize :email_at_notices, type: Array, coder: YAML

    has_many :watchers,
      class_name: "Errbit::Watcher",
      foreign_key: :errbit_app_id,
      inverse_of: :app,
      dependent: :destroy

    has_many :problems,
      class_name: "Errbit::Problem",
      foreign_key: :errbit_app_id,
      inverse_of: :app,
      dependent: :destroy

    has_many :notices,
      class_name: "Errbit::Notice",
      foreign_key: :errbit_app_id,
      inverse_of: :app,
      dependent: :destroy

    has_one :notice_fingerprinter,
      class_name: "Errbit::NoticeFingerprinter",
      foreign_key: :errbit_app_id,
      inverse_of: :app,
      dependent: :destroy

    has_one :issue_tracker,
      class_name: "Errbit::IssueTracker",
      foreign_key: :errbit_app_id,
      inverse_of: :app,
      dependent: :destroy

    has_one :notification_service,
      class_name: "Errbit::NotificationService",
      foreign_key: :errbit_app_id,
      inverse_of: :app,
      dependent: :destroy

    accepts_nested_attributes_for :issue_tracker,
      allow_destroy: true,
      reject_if: proc { |attrs| !ErrbitPlugin::Registry.issue_trackers.keys.map(&:to_s).include?(attrs[:type_tracker].to_s) }
    accepts_nested_attributes_for :notification_service,
      allow_destroy: true,
      reject_if: proc { |attrs| !Errbit::NotificationService.subclasses.map(&:to_s).include?(attrs[:type].to_s) }
    accepts_nested_attributes_for :notice_fingerprinter

    before_validation :generate_api_key, on: :create
    before_save :normalize_github_repo

    validates :name, presence: true, uniqueness: {allow_blank: true}
    validates :api_key, presence: true, uniqueness: {allow_blank: true}
    validates_associated :issue_tracker
    validates_associated :notice_fingerprinter

    scope :search, ->(value) { where(arel_table[:name].matches("%#{value}%")) }

    def notify_on_errs
      self[:notify_on_errs] != false
    end
    alias_method :notify_on_errs?, :notify_on_errs

    def emailable?
      notify_on_errs? && notification_recipients.any?
    end

    def notification_recipients
      if notify_all_users
        (Errbit::User.all.map(&:email).reject(&:blank?) + watchers.map(&:address)).uniq
      else
        watchers.map(&:address)
      end
    end

    def watched_by?(user)
      watchers.where(errbit_user_id: user.id).exists?
    end

    def repo_branch
      repository_branch.present? ? repository_branch : "main"
    end

    def github_repo?
      github_repo.present?
    end

    def github_url
      "#{Errbit::Config.github_url}/#{github_repo}" if github_repo?
    end

    def github_url_to_file(file)
      "#{github_url}/blob/#{repo_branch}/#{file}"
    end

    def bitbucket_repo?
      bitbucket_repo.present?
    end

    def bitbucket_url
      "https://bitbucket.org/#{bitbucket_repo}" if bitbucket_repo?
    end

    def bitbucket_url_to_file(file)
      "#{bitbucket_url}/src/#{repo_branch}/#{file}"
    end

    def email_at_notices
      Errbit::Config.per_app_email_at_notices ? (super || Errbit::Config.email_at_notices) : Errbit::Config.email_at_notices
    end

    def regenerate_api_key!
      update!(api_key: SecureRandom.hex)
    end

    def self.find_by_api_key!(key)
      find_by!(api_key: key)
    end

    # Accepts a hash with the following attributes:
    #
    # * <tt>:error_class</tt>  - required to create a new Problem
    # * <tt>:environment</tt>  - required to create a new Problem
    # * <tt>:fingerprint</tt>  - a unique value identifying the err/notice group
    #
    def find_or_create_err!(attrs)
      err = Errbit::Err.where(fingerprint: attrs[:fingerprint]).first
      return err if err

      problem = problems.create!(
        error_class: attrs[:error_class],
        environment: attrs[:environment],
        app_name: name
      )
      problem.errs.create!(attrs.slice(:fingerprint))
    end

    def issue_tracker_configured?
      issue_tracker.present? && issue_tracker.configured?
    end

    def notification_service_configured?
      notification_service.present? &&
        notification_service.class < Errbit::NotificationService &&
        notification_service.configured?
    end

    def unresolved_count
      @unresolved_count ||= problems.unresolved.count
    end

    def problem_count
      @problem_count ||= problems.count
    end

    # Compare by unresolved errs, then by total problem count, then by name.
    def <=>(other)
      (other.unresolved_count <=> unresolved_count).nonzero? ||
        (other.problem_count <=> problem_count).nonzero? ||
        name <=> other.name
    end

    # Copy field values (and the singular relations) from another app. Used by
    # the "New App" form's "copy attributes from existing app" feature.
    def copy_attributes_from(app_id)
      copy_app = Errbit::App.find_by(id: app_id)
      return if copy_app.blank?

      excluded = %w[id bson_id name created_at updated_at]
      (copy_app.attributes.keys - excluded).each do |k|
        send(:"#{k}=", copy_app.send(k))
      end

      if (it = copy_app.issue_tracker)
        build_issue_tracker(it.attributes.except(*excluded, "errbit_app_id"))
      end

      if (ns = copy_app.notification_service)
        attrs = ns.attributes.except(*excluded, "errbit_app_id")
        build_notification_service(attrs).becomes!(ns.class)
      end

      copy_app.watchers.each do |w|
        watchers.build(w.attributes.except(*excluded, "errbit_app_id"))
      end
    end

    def attributes_for_super_diff
      {
        id: id,
        name: name
      }
    end

    private

    def generate_api_key
      self.api_key ||= SecureRandom.hex
    end

    def normalize_github_repo
      return if github_repo.blank?

      github_host = URI.parse(Errbit::Config.github_url).host
      github_host = Regexp.escape(github_host)

      self.github_repo = github_repo.strip
      self.github_repo = github_repo.sub(%r{(git@|https?://)#{github_host}(/|:)}, "")
      self.github_repo = github_repo.sub(/\.git$/, "")
    end
  end
end
