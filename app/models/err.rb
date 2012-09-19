# Represents a set of Notices which can be automatically
# determined to refer to the same Error (Errbit groups
# notices into errs by a notice's fingerprint.)

class Err
  include Mongoid::Document
  include Mongoid::Timestamps

  field :error_class, :default => "UnknownError"
  field :component
  field :action
  field :environment, :default => "unknown"
  field :fingerprint

  belongs_to :problem
  index :problem_id
  index :error_class
  index :fingerprint

  has_many :notices, :inverse_of => :err, :dependent => :destroy

  delegate :app, :resolved?, :to => :problem

end

