# Represents a set of Notices which can be automatically
# determined to refer to the same Error (Errbit groups
# notices into errs by a notice's fingerprint.)

class Err < ActiveRecord::Base

  belongs_to :problem, inverse_of: :errs
  has_many :notices, inverse_of: :err, dependent: :destroy
  has_one :notice
  has_many :comments, dependent: :destroy

  validates_presence_of :problem, :fingerprint

  delegate :app, :resolved?, to: :problem

end
