# frozen_string_literal: true

# Represents a set of Notices which can be automatically
# determined to refer to the same Error (Errbit groups
# notices into errs by a notice's fingerprint.)

class Err
  include Mongoid::Document
  include Mongoid::Timestamps

  field :fingerprint

  index problem_id: 1
  index fingerprint: 1

  belongs_to :problem
  has_many :notices, inverse_of: :err, dependent: :destroy

  validates :problem_id, :fingerprint, presence: true

  delegate :app, :resolved?, to: :problem
end
