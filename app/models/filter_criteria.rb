class FilterCriteria
  include Mongoid::Document

  field :message
  field :error_class
  field :url
  field :where

  def pass? notice
    matches = []
    [:message, :error_class, :url, :where].each do |sym|
      if self[sym].present?
        regex = Regexp.new self[sym]
        matches << ( regex === notice.send(sym) )
      end
    end
    matches.any? { |m| m == false }
  end
end
