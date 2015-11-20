# Include to do a Search
# TODO: Need to be in a Dedicated Object ProblemsSearch with params like input
#
module ProblemsSearcher
  extend ActiveSupport::Concern

  included do
    expose(:params_sort) do
      if %w(app message last_notice_at last_deploy_at count).member?(params[:sort])
        params[:sort]
      else
        "last_notice_at"
      end
    end

    expose(:params_order) do
      if %w(asc desc).member?(params[:order])
        params[:order]
      else
        'desc'
      end
    end

    expose(:selected_problems) do
      Array(Problem.find(err_ids))
    end

    expose(:err_ids) do
      (params[:problems] || []).compact
    end
  end
end
