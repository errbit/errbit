class App
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :api_key
  field :resolve_errs_on_deploy, :type => Boolean, :default => false
  key :name
  
  embeds_many :watchers
  embeds_many :deploys
  references_many :errs, :dependent => :destroy
  
  before_validation :generate_api_key, :on => :create
  
  validates_presence_of :name, :api_key
  validates_uniqueness_of :name, :allow_blank => true
  validates_uniqueness_of :api_key, :allow_blank => true
  validates_associated :watchers
  
  accepts_nested_attributes_for :watchers, :allow_destroy => true,
    :reject_if => proc { |attrs| attrs[:user_id].blank? && attrs[:email].blank? }
  
  # Mongoid Bug: find(id) on association proxies returns an Enumerator
  def self.find_by_id!(app_id)
    where(:_id => app_id).first || raise(Mongoid::Errors::DocumentNotFound.new(self,app_id))
  end
  
  def self.find_by_api_key!(key)
    where(:api_key => key).first || raise(Mongoid::Errors::DocumentNotFound.new(self,key))
  end
  
  def last_deploy_at
    deploys.last && deploys.last.created_at
  end
  
  protected
  
    def generate_api_key
      self.api_key ||= ActiveSupport::SecureRandom.hex
    end
  
end
