# Represents a set of Notices which can be automatically
# determined to refer to the same Error (Errbit groups
# notices into errs by a notice's fingerprint.)

class Err
  include Mongoid::Document
  include Mongoid::Timestamps

  field :klass
  field :component
  field :action
  field :environment
  field :fingerprint

  belongs_to :problem
  index :problem_id

  has_many :notices, :inverse_of => :err, :dependent => :destroy

  validates_presence_of :klass, :environment

  delegate :app, :resolved?, :to => :problem

end

