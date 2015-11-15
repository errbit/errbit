class App
  include Comparable
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :api_key
  field :github_repo
  field :bitbucket_repo
  field :asset_host
  field :repository_branch
  field :current_app_version
  field :resolve_errs_on_deploy, type: Boolean, default: false
  field :notify_all_users, type: Boolean, default: false
  field :notify_on_errs, type: Boolean, default: true
  field :notify_on_deploys, type: Boolean, default: false
  field :email_at_notices, type: Array, default: Errbit::Config.email_at_notices

  # Some legacy apps may have string as key instead of BSON::ObjectID
  # identity :type => String
  field :_id,
    type:          String,
    pre_processed: true,
    default:       -> { BSON::ObjectId.new.to_s }

  embeds_many :watchers
  embeds_many :deploys
  embeds_one :issue_tracker, class_name: 'IssueTracker'
  embeds_one :notification_service
  embeds_one :notice_fingerprinter, autobuild: true

  has_many :problems, inverse_of: :app, dependent: :destroy

  before_validation :generate_api_key, on: :create
  before_save :normalize_github_repo
  after_update :store_cached_attributes_on_problems

  validates :name, :api_key, presence: true, uniqueness: { allow_blank: true }
  validates_associated :watchers
  validates_associated :notice_fingerprinter
  validate :check_issue_tracker

  accepts_nested_attributes_for :watchers,
    allow_destroy: true,
    reject_if:     proc { |attrs| attrs[:user_id].blank? && attrs[:email].blank? }
  accepts_nested_attributes_for :issue_tracker,
    allow_destroy: true,
    reject_if:     proc { |attrs| !ErrbitPlugin::Registry.issue_trackers.keys.map(&:to_s).include?(attrs[:type_tracker].to_s) }
  accepts_nested_attributes_for :notification_service,
    allow_destroy: true,
    reject_if:     proc { |attrs| !NotificationService.subclasses.map(&:to_s).include?(attrs[:type].to_s) }
  accepts_nested_attributes_for :notice_fingerprinter

  scope :watched_by, lambda { |user|
    where watchers: { "$elemMatch" => { "user_id" => user.id } }
  }

  def watched_by?(user)
    watchers.pluck("user_id").include? user.id
  end

  # Acceps a hash with the following attributes:
  #
  # * <tt>:error_class</tt> - the class of error (required to create a new Problem)
  # * <tt>:environment</tt> - the environment the source app was running in (required to create a new Problem)
  # * <tt>:fingerprint</tt> - a unique value identifying the notice
  #
  def find_or_create_err!(attrs)
    err = Err.where(fingerprint: attrs[:fingerprint]).first
    return err if err

    problem = problems.create!(
      error_class: attrs[:error_class],
      environment: attrs[:environment],
      app_name:    name
    )
    problem.errs.create!(attrs.slice(:fingerprint, :problem_id))
  end

  # Mongoid Bug: find(id) on association proxies returns an Enumerator
  def self.find_by_id!(app_id)
    find app_id
  end

  def self.find_by_api_key!(key)
    find_by(api_key: key)
  end

  def last_deploy_at
    (last_deploy = deploys.last) && last_deploy.created_at
  end

  # Legacy apps don't have notify_on_errs and notify_on_deploys params
  def notify_on_errs
    !(super == false)
  end
  alias_method :notify_on_errs?, :notify_on_errs

  def emailable?
    notify_on_errs? && notification_recipients.any?
  end

  def notify_on_deploys
    !(super == false)
  end
  alias_method :notify_on_deploys?, :notify_on_deploys

  def repo_branch
    repository_branch.present? ? repository_branch : 'master'
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

  def issue_tracker_configured?
    issue_tracker.present? && issue_tracker.configured?
  end

  def notification_service_configured?
    (notification_service.class < NotificationService) &&
      notification_service.configured?
  end

  def notification_recipients
    if notify_all_users
      (User.all.map(&:email).reject(&:blank?) + watchers.map(&:address)).uniq
    else
      watchers.map(&:address)
    end
  end

  # Copy app attributes from another app.
  def copy_attributes_from(app_id)
    copy_app = App.where(_id: app_id).first
    return if copy_app.blank?

    # Copy fields
    (copy_app.fields.keys - %w(_id name created_at updated_at)).each do |k|
      send("#{k}=", copy_app.send(k))
    end
    # Clone the embedded objects that can be changed via apps/edit (ignore errs & deploys, etc.)
    %w(watchers issue_tracker notification_service).each do |relation|
      if (obj = copy_app.send(relation))
        send("#{relation}=", obj.is_a?(Array) ? obj.map(&:clone) : obj.clone)
      end
    end
  end

  def unresolved_count
    @unresolved_count ||= problems.unresolved.count
  end

  def problem_count
    @problem_count ||= problems.count
  end

  # Compare by number of unresolved errs, then problem counts.
  def <=>(other)
    (other.unresolved_count <=> unresolved_count).nonzero? ||
      (other.problem_count <=> problem_count).nonzero? ||
      name <=> other.name
  end

  def email_at_notices
    Errbit::Config.per_app_email_at_notices ? super : Errbit::Config.email_at_notices
  end

  def regenerate_api_key!
    update_attribute(:api_key, SecureRandom.hex)
  end

protected

  def store_cached_attributes_on_problems
    Problem.where(app_id: id).update_all(
      app_name: name
    )
  end

  def generate_api_key
    self.api_key ||= SecureRandom.hex
  end

  def check_issue_tracker
    return if issue_tracker.blank?

    issue_tracker.valid?
    issue_tracker.errors.full_messages.each do |error|
      errors[:base] << error
    end if issue_tracker.errors
  end

  def normalize_github_repo
    return if github_repo.blank?
    github_host = URI.parse(Errbit::Config.github_url).host
    github_host = Regexp.escape(github_host)
    github_repo.strip!
    github_repo.sub!(%r{(git@|https?://)#{github_host}(/|:)}, '')
    github_repo.sub!(/\.git$/, '')
  end
end
