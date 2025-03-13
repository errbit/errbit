module ProblemsSearcher
  extend ActiveSupport::Concern

  included do
    expose(:params_sort) do
      if %w(environment app message last_notice_at count).member?(params[:sort])
        params[:sort]
      else
        "last_notice_at"
      end
    end

    expose(:params_order) do
      if %w(asc desc).member?(params[:order])
        params[:order]
      else
        "desc"
      end
    end

    expose(:selected_problems) do
      Array(Problem.find(err_ids))
    end

    expose(:selected_problems_ids) do
      selected_problems.map(&:id).map(&:to_s)
    end

    expose(:err_ids) do
      (params[:problems] || []).compact
    end
  end
end
