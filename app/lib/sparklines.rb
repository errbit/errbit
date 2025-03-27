# frozen_string_literal: true

module Sparklines
  class << self
    def for_relative_percentages(array_of_relative_percentages)
      bars = array_of_relative_percentages.map do |percent|
        "<i style='height:#{percent}%'></i>"
      end.join
      "<div class='spark'>#{bars}</div>".html_safe
    end
  end
end
