module TrendLines
  MINIMUM_BAR_CHART_SCALE_STEPS = 10
  NO_OF_DAYS_TO_CHART           = ENV["ERROR_TREND_CHART_DAYS"].present? ? ENV["ERROR_TREND_CHART_DAYS"].to_i : 14

  def self.enabled?
    ENV["ERROR_TREND_CHART_ENABLE"] == "true"
  end

  def self.beginning_of_range
    NO_OF_DAYS_TO_CHART.days.ago
  end
end
