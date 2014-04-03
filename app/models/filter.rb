class Filter
  include Mongoid::Document

  FIELDS = [:message, :error_class, :url, :where]

  field :description
  field :message
  field :error_class
  field :url
  field :where

  scope :global, -> { where(:app => nil) }

  belongs_to :app
  delegate :name, :to => :app, :prefix => true

  validates :description, :presence => true
  validate :at_least_one_criteria_present

  def pass? notice
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
    present = FIELDS.map { |sym| self[sym] }.map(&:present?)
    errors.add(:base, 'At least one criteria must be present.') if present.none?
  end
end
