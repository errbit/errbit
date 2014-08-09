module UsersSearcher
  extend ActiveSupport::Concern

  included do

    expose(:user_params_sort) {
      unless %w{name username email admin}.member?(params[:user_sort])
        "name"
      else
        params[:user_sort]
      end
    }

    expose(:user_params_order){
      unless %w{asc desc}.member?(params[:user_order])
        'desc'
      else
        params[:user_order]
      end
    }
  end
end
