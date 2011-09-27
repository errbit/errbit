class User
  PER_PAGE = 30
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :token_authenticatable

  field :email
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

  protected

    def destroy_watchers
      watchers.each(&:destroy)
    end
end

