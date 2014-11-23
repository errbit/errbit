class User < ActiveRecord::Base
  PER_PAGE = 30

  devise *Errbit::Config.devise_modules

  before_save :ensure_authentication_token
  after_initialize :default_values

  validates_presence_of :name
  validates_uniqueness_of :github_login, allow_nil: true

  has_many :apps, through: :watchers
  has_many :watchers

  scope :with_not_blank_email, -> { where("email IS NOT NULL AND email != ''") }

  if Errbit::Config.user_has_username
    validates_presence_of :username
  end

  def default_values
    if self.new_record?
      self.admin = false if self.admin.nil?
      self.per_page ||= PER_PAGE
      self.time_zone ||= "UTC"
    end
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

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def self.token_authentication_key
    :auth_token
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
