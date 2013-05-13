class User
  PER_PAGE = 30
  include Mongoid::Document
  include Mongoid::Timestamps

  devise *Errbit::Config.devise_modules

  field :email
  field :github_login
  field :github_oauth_token
  field :name
  field :admin, :type => Boolean, :default => false
  field :per_page, :type => Fixnum, :default => PER_PAGE
  field :time_zone, :default => "UTC"

  after_destroy :destroy_watchers
  before_save :ensure_authentication_token

  validates_presence_of :name
  validates_uniqueness_of :github_login, :allow_nil => true

  attr_protected :admin

  has_many :apps, :foreign_key => 'watchers.user_id'

  if Errbit::Config.user_has_username
    field :username
    validates_presence_of :username
  end

  def watchers
    apps.map(&:watchers).flatten.select {|w| w.user_id.to_s == id.to_s}
  end

  def per_page
    super || PER_PAGE
  end

  def watching?(app)
    apps.all.include?(app)
  end

  def password_required?
    github_login.present? ? false : super
  end

  def github_account?
    github_login.present? && github_oauth_token.present?
  end

  def can_create_github_issues?
    github_account? && Errbit::Config.github_access_scope.include?('repo')
  end

  def github_login=(login)
    if login.is_a?(String) && login.strip.empty?
      login = nil
    end
    self[:github_login] = login
  end

  protected

    def destroy_watchers
      watchers.each(&:destroy)
    end
end

