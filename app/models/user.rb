class User
  PER_PAGE = 30
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :token_authenticatable

  field :name
  field :admin, :type => Boolean, :default => false
  field :per_page, :type => Fixnum, :default => PER_PAGE

  after_destroy :destroy_watchers
  before_save :ensure_authentication_token
  
  validates_presence_of :name
  
  attr_protected :admin
  
  # Mongoid doesn't seem to currently support
  # referencing embedded documents
  def watchers
    App.all.map(&:watchers).flatten.select {|w| w.user_id.to_s == id.to_s}
  end

  def per_page
    self[:per_page] || PER_PAGE
  end
  
  def apps
    # This is completely wasteful but became necessary
    # due to bugs in Mongoid 
    app_ids = watchers.map {|w| w.app.id}
    App.any_in(:_id => app_ids)
  end
  
  def watching?(app)
    apps.all.include?(app)
  end
  
  protected
  
    def destroy_watchers
      watchers.each(&:destroy)
    end
end
