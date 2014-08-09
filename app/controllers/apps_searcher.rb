# Include to do a Search
# TODO: Need to be in a Dedicated Object ProblemsSearch with params like input
#
module AppsSearcher
  extend ActiveSupport::Concern

  included do

    expose(:app_params_sort) {
      unless %w{name last_deploy_at count}.member?(params[:app_sort])
        "name"
      else
        params[:app_sort]
      end
    }

    expose(:app_params_order){
      unless %w{asc desc}.member?(params[:app_order])
        'asc'
      else
        params[:app_order]
      end
    }

  end
end
