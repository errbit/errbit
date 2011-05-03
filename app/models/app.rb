class App
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :api_key
  field :resolve_errs_on_deploy, :type => Boolean, :default => false
  field :notify_on_errs, :type => Boolean, :default => true
  field :notify_on_deploys, :type => Boolean, :default => true

  # Some legacy apps may have sting as key instead of BSON::ObjectID
  identity :type => String
  # There seems to be a Mongoid bug making it impossible to use String identity with references_many feature:
  # https://github.com/mongoid/mongoid/issues/703
  # Using 32 character string as a workaround.
  before_create do |r|
    r.id = ActiveSupport::SecureRandom.hex
  end

  embeds_many :watchers
  embeds_many :deploys
  embeds_one :issue_tracker
  references_many :errs, :dependent => :destroy

  before_validation :generate_api_key, :on => :create

  validates_presence_of :name, :api_key
  validates_uniqueness_of :name, :allow_blank => true
  validates_uniqueness_of :api_key, :allow_blank => true
  validates_associated :watchers
  validate :check_issue_tracker

  accepts_nested_attributes_for :watchers, :allow_destroy => true,
    :reject_if => proc { |attrs| attrs[:user_id].blank? && attrs[:email].blank? }
  accepts_nested_attributes_for :issue_tracker, :allow_destroy => true,
    :reject_if => proc { |attrs| !%w(lighthouseapp redmine pivotal).include?(attrs[:issue_tracker_type]) }

  # Mongoid Bug: find(id) on association proxies returns an Enumerator
  def self.find_by_id!(app_id)
    where(:_id => app_id).first || raise(Mongoid::Errors::DocumentNotFound.new(self,app_id))
  end

  def self.find_by_api_key!(key)
    where(:api_key => key).first || raise(Mongoid::Errors::DocumentNotFound.new(self,key))
  end

  def last_deploy_at
    deploys.last && deploys.last.created_at
  end

  # Legacy apps don't have notify_on_errs and notify_on_deploys params
  def notify_on_errs
    !(self[:notify_on_errs] == false)
  end
  alias :notify_on_errs? :notify_on_errs

  def notify_on_deploys
    !(self[:notify_on_deploys] == false)
  end
  alias :notify_on_deploys? :notify_on_deploys

  protected

    def generate_api_key
      self.api_key ||= ActiveSupport::SecureRandom.hex
    end

    def check_issue_tracker
      if issue_tracker.present?
        issue_tracker.valid?
        issue_tracker.errors.full_messages.each do |error|
          errors[:base] << error
        end if issue_tracker.errors
      end
    end
end
