class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :api_key
  key :name
  
  embeds_many :watchers
  embeds_many :deploys
  references_many :errs, :dependent => :destroy
  
  before_validation :generate_api_key, :on => :create
  
  validates_presence_of :name, :api_key
  validates_uniqueness_of :name, :api_key, :allow_blank => true
  
  accepts_nested_attributes_for :watchers,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  
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
