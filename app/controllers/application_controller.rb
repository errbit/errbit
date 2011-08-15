class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :authenticate_user!
  
  rescue_from ActionController::RedirectBackError, :with => :redirect_to_root
  
  
protected
  
  def redirect_to_root
    redirect_to(root_path)
  end
  
  def require_admin!
    redirect_to(root_path) and return(false) unless user_signed_in? && current_user.admin?
  end
  
end
