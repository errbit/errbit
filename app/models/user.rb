class User
  PER_PAGE = 30
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :token_authenticatable, :omniauthable

  field :email
  field :github_login
  field :name
  field :admin, :type => Boolean, :default => false
  field :per_page, :type => Fixnum, :default => PER_PAGE
  field :time_zone, :default => "UTC"

  after_destroy :destroy_watchers
  before_save :ensure_authentication_token

  validates_presence_of :name

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
    self[:per_page] || PER_PAGE
  end

  def watching?(app)
    apps.all.include?(app)
  end

  def self.find_for_github_oauth(omniauth_env)
    data = omniauth_env.extra.raw_info

    User.where(:github_login => data.login).first
  end

  def password_required?
    github_login.present? ? false : super
  end

  protected

    def destroy_watchers
      watchers.each(&:destroy)
    end
end

