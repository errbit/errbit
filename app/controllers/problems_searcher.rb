# Include to do a Search
# TODO: Need to be in a Dedicated Object ProblemsSearch with params like input
#
module ProblemsSearcher
  extend ActiveSupport::Concern

  included do
    expose(:params_sort) {
      if %w(app message last_notice_at last_deploy_at count).member?(params[:sort])
        params[:sort]
      else
        "last_notice_at"
      end
    }

    expose(:params_order) {
      if %w(asc desc).member?(params[:order])
        params[:order]
      else
        'desc'
      end
    }

    expose(:selected_problems) {
      Array(Problem.find(err_ids))
    }

    expose(:err_ids) {
      (params[:problems] || []).compact
    }
  end
end
