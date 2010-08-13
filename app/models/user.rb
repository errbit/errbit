class User
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :token_authenticatable

  field :name
  field :admin, :type => Boolean, :default => false
  
  validates_presence_of :name

end
