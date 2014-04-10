class Filter
  include Mongoid::Document

  FIELDS = [:message, :error_class, :url, :where]

  field :description
  field :message
  field :error_class
  field :url
  field :where

  scope :global, -> { where(app_id: nil, app_id: '') }

  belongs_to :app
  delegate :name, to: :app, prefix: true

  validates :description, presence: true
  validate :at_least_one_criteria_present

  def pass?(notice)
    matches = FIELDS.map { |sym| match?(sym, notice) if self[sym].present? }
    matches.any? { |m| m == false }
  end

  def global?
    app.nil?
  end

  private

  def match?(attribute, notice)
    criteria = Regexp.new self[attribute]
    criteria === notice.send(attribute)
  end

  def at_least_one_criteria_present
    all_empty = FIELDS.map { |sym| self[sym].present? }.none?
    errors.add(:base, 'At least one criteria must be present.') if all_empty
  end
end
