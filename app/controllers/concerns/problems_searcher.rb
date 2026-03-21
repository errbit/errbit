# frozen_string_literal: true

module ProblemsSearcher
  extend ActiveSupport::Concern

  included do
    helper_method :params_sort, :params_order, :selected_problems, :selected_problems_ids, :err_ids
  end

  private

  def params_sort
    @params_sort ||= if ["environment", "app", "message", "last_notice_at", "count"].member?(params[:sort])
      params[:sort]
    else
      "last_notice_at"
    end
  end

  def params_order
    @params_order ||= if ["asc", "desc"].member?(params[:order])
      params[:order]
    else
      "desc"
    end
  end

  def selected_problems
    @selected_problems ||= Array(Problem.find(err_ids))
  end

  def selected_problems_ids
    @selected_problems_ids ||= selected_problems.map(&:id).map(&:to_s)
  end

  def err_ids
    @err_ids ||= (params[:problems] || []).compact
  end
end
