class User
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :token_authenticatable

  field :name
  field :admin, :type => Boolean, :default => false
    
  after_destroy :destroy_watchers
  
  validates_presence_of :name
  
  # Mongoid doesn't seem to currently support
  # referencing embedded documents
  def watchers
    App.all.map(&:watchers).flatten.select {|w| w.user_id == id}
  end
  
  def apps
    App.where('watchers.user_id' => id)
  end
  
  protected
  
    def destroy_watchers
      watchers.each(&:destroy)
    end
end
