class Watcher
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email
  
  embedded_in :project, :inverse_of => :watchers
  
  validates_presence_of :email
  
end
