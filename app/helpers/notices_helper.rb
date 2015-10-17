# encoding: utf-8
module NoticesHelper
  def notice_atom_summary(notice)
    render "notices/atom_entry", :notice => notice
  end

  def bar_chart_scale_steps(maximum_data_point)
    [maximum_data_point, TrendLines::MINIMUM_BAR_CHART_SCALE_STEPS].max
  end

  def bar_chart_x_axis_labels(show_labels)
    if show_labels
      dates = (TrendLines.beginning_of_range.to_date .. Time.now.to_date).to_a
      dates.map { |date| date.to_s(:short) }
    else
      Array.new(TrendLines::NO_OF_DAYS_TO_CHART, "")
    end
  end
end
