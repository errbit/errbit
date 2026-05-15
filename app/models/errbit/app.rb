# frozen_string_literal: true

module Errbit
  class App < ApplicationRecord
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

    before_validation :generate_api_key, on: :create
    before_save :normalize_github_repo

    validates :name, presence: true, uniqueness: {allow_blank: true}
    validates :api_key, presence: true, uniqueness: {allow_blank: true}

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
