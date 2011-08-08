class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user!

  protected

    def require_admin!
      redirect_to(root_path) and return(false) unless user_signed_in? && current_user.admin?
    end

end
