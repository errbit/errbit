# Include to do a Search
# TODO: Need to be in a Dedicated Object ProblemsSearch with params like input
#
module ProblemsSearcher
  extend ActiveSupport::Concern

  included do

    expose(:params_sort) {
      unless %w{app message last_notice_at last_deploy_at count}.member?(params[:sort])
        "last_notice_at"
      else
        params[:sort]
      end
    }

    expose(:params_order){
      unless %w{asc desc}.member?(params[:order])
        'desc'
      else
        params[:order]
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
