class FilterCriteria
  include Mongoid::Document

  field :message
  field :error_class
  field :url
  field :where

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
end
