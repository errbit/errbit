class App
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :api_key
  field :github_url
  field :resolve_errs_on_deploy, :type => Boolean, :default => false
  field :notify_all_users, :type => Boolean, :default => false
  field :notify_on_errs, :type => Boolean, :default => true
  field :notify_on_deploys, :type => Boolean, :default => false
  field :email_at_notices, :type => Array, :default => Errbit::Config.email_at_notices

  # Some legacy apps may have string as key instead of BSON::ObjectID
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
  has_many :problems, :inverse_of => :app, :dependent => :destroy

  before_validation :generate_api_key, :on => :create
  before_save :normalize_github_url
  after_update :store_cached_attributes_on_problems

  validates_presence_of :name, :api_key
  validates_uniqueness_of :name, :allow_blank => true
  validates_uniqueness_of :api_key, :allow_blank => true
  validates_associated :watchers
  validate :check_issue_tracker

  accepts_nested_attributes_for :watchers, :allow_destroy => true,
    :reject_if => proc { |attrs| attrs[:user_id].blank? && attrs[:email].blank? }
  accepts_nested_attributes_for :issue_tracker, :allow_destroy => true,
    :reject_if => proc { |attrs| !IssueTracker.subclasses.map(&:to_s).include?(attrs[:type].to_s) }


  # Processes a new error report.
  #
  # Accepts either XML or a hash with the following attributes:
  #
  # * <tt>:klass</tt> - the class of error
  # * <tt>:message</tt> - the error message
  # * <tt>:backtrace</tt> - an array of stack trace lines
  #
  # * <tt>:request</tt> - a hash of values describing the request
  # * <tt>:server_environment</tt> - a hash of values describing the server environment
  #
  # * <tt>:api_key</tt> - the API key with which the error was reported
  # * <tt>:notifier</tt> - information to identify the source of the error report
  #
  def self.report_error!(*args)
    report = ErrorReport.new(*args)
    report.generate_notice!
  end


  # Processes a new error report.
  #
  # Accepts a hash with the following attributes:
  #
  # * <tt>:klass</tt> - the class of error
  # * <tt>:message</tt> - the error message
  # * <tt>:backtrace</tt> - an array of stack trace lines
  #
  # * <tt>:request</tt> - a hash of values describing the request
  # * <tt>:server_environment</tt> - a hash of values describing the server environment
  #
  # * <tt>:notifier</tt> - information to identify the source of the error report
  #
  def report_error!(hash)
    report = ErrorReport.new(hash.merge(:api_key => api_key))
    report.generate_notice!
  end

  def find_or_create_err!(attrs)
    Err.where(attrs).first || problems.create!.errs.create!(attrs)
  end

  # Mongoid Bug: find(id) on association proxies returns an Enumerator
  def self.find_by_id!(app_id)
    find app_id
  end

  def self.find_by_api_key!(key)
    where(:api_key => key).first || raise(Mongoid::Errors::DocumentNotFound.new(self,key))
  end

  def last_deploy_at
    (last_deploy = deploys.last) && last_deploy.created_at
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


  def github_url?
    self.github_url.present?
  end

  def github_url_to_file(file)
    "#{self.github_url}/blob/master#{file}"
  end

  def issue_tracker_configured?
    !!(issue_tracker && issue_tracker.class < IssueTracker && issue_tracker.project_id.present?)
  end

  def notification_recipients
    notify_all_users ? User.all.map(&:email).reject(&:blank?) : watchers.map(&:address)
  end

  # Copy app attributes from another app.
  def copy_attributes_from(app_id)
    if copy_app = App.where(:_id => app_id).first
      # Copy fields
      (copy_app.fields.keys - %w(_id name created_at updated_at)).each do |k|
        self.send("#{k}=", copy_app.send(k))
      end
      # Clone the embedded objects that can be changed via apps/edit (ignore errs & deploys, etc.)
      %w(watchers issue_tracker).each do |relation|
        if obj = copy_app.send(relation)
          self.send("#{relation}=", obj.is_a?(Array) ? obj.map(&:clone) : obj.clone)
        end
      end
    end
  end

  protected

    def store_cached_attributes_on_problems
      problems.each(&:cache_app_attributes)
    end

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

    def normalize_github_url
      return if self.github_url.blank?
      self.github_url.gsub!(%r{^http://|git@}, 'https://')
      self.github_url.gsub!(/github\.com:/, 'github.com/')
      self.github_url.gsub!(/\.git$/, '')
    end
end

