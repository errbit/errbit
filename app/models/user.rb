class User
  include Mongoid::Document

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, 
         :validatable, :token_authenticatable

  field :name
  field :admin, :type => Boolean, :default => false
  
  validates_presence_of :name

end
