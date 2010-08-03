class Error
  include Mongoid::Document
  
  embeds_many :notices
  
  def self.for(attrs)
    self.where(attrs).first || create(attrs)
  end
  
end