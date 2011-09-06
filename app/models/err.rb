# An Err is a group of notices that can programatically
# be determined to be equal. (Errbit groups notices into
# errs by a notice's fingerprint.)

class Err
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :klass
  field :component
  field :action
  field :environment
  field :fingerprint
  
  belongs_to :problem
  has_many :notices, :inverse_of => :err, :dependent => :destroy
  
  validates_presence_of :klass, :environment, :problem
  
  delegate :app,
           :resolved?,
           :to => :problem
  
  
end
