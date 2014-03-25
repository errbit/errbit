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

  ## Devise field
  ### Database Authenticatable
  field :encrypted_password, :type => String

  ### Recoverable
  field :reset_password_token, :type => String
  field :reset_password_sent_at, :type => Time

  ### Rememberable
  field :remember_created_at, :type => Time

  ### Trackable
  field :sign_in_count,      :type => Integer
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  ### Token_authenticatable
  field :authentication_token, :type => String

  index :authentication_token => 1

  ### GDS SSO
  field :uid, :type => String
  field :remotely_signed_out, :type => Boolean, :default => false
  field :permissions, :type => Array, :default => []
  index :uid => 1

  before_save :ensure_authentication_token

  validates_presence_of :name
  validates_uniqueness_of :github_login, :allow_nil => true

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
    (github_login.present? or uid.present?) ? false : super
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

  def active_for_authentication?
    super && ! remotely_signed_out
  end

  def set_remotely_signed_out!
    self.update_attribute(:remotely_signed_out, true) unless self.remotely_signed_out
  end

  def clear_remotely_signed_out!
    self.update_attribute(:remotely_signed_out, false) if self.remotely_signed_out
  end

  def self.find_for_gds_oauth(auth_hash)
    return false unless auth_hash.has_key?('info') and auth_hash.has_key?('extra') and auth_hash['extra'].has_key?('user')

    permissions = auth_hash['extra']['user']['permissions'] || []
    return false unless permissions.include?('signin')

    user = self.where(:uid => auth_hash['uid']).first_or_initialize
    user.permissions = permissions
    user.admin = permissions.include?("admin")
    user.name = auth_hash['info']['name']
    user.email = auth_hash['info']['email']
    user.save and user
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
