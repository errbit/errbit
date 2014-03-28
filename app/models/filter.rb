class Filter
  include Mongoid::Document

  field :description
  field :message
  field :error_class
  field :url
  field :where

  belongs_to :app

  validates :description, :presence => true
  validate :at_least_one_criteria_present

  def pass? notice
    matches = []
    [:message, :error_class, :url, :where].each do |sym|
      matches << match_criteria(sym, notice) if self[sym].present?
    end
    matches.any? { |m| m == false }
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
