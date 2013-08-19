# Represents a set of Notices which can be automatically
# determined to refer to the same Error (Errbit groups
# notices into errs by a notice's fingerprint.)

class Err
  include Mongoid::Document
  include Mongoid::Timestamps

  field :fingerprint

  index :problem_id
  index :fingerprint

  belongs_to :problem
  has_many :notices, :inverse_of => :err, :dependent => :destroy

  validates_presence_of :problem_id, :fingerprint

  delegate :app, :resolved?, :to => :problem

end
