class Deploy
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :username
  field :repository
  field :environment
  field :revision
  
  embedded_in :project, :inverse_of => :deploys
  
  validates_presence_of :username, :environment
  
end
