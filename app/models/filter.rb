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
    matches = []
    FIELDS.each do |sym|
      matches << match_criteria(sym, notice) if self[sym].present?
    end
    matches.any? { |m| m == false }
  end

  def global?
    app.nil?
  end

  private

  def match_criteria(attribute, notice)
    criteria = Regexp.new self[attribute]
    criteria === notice.send(attribute)
  end

  def at_least_one_criteria_present
    present = [message, error_class, url, where].map(&:present?)
    unless present.any?
      errors.add(:base, 'At least one criteria must be present.')
    end
  end
end
