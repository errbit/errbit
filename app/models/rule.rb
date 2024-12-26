
class Rule
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :condition, type: String

  belongs_to :app

  validates :name, presence: true
  validates :condition, presence: true
end
