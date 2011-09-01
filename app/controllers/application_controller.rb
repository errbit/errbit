class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user!

  # Devise override - After login, if there is only one app,
  # redirect to that app's path instead of the root path (apps#index).
  def stored_location_for(resource)
    location = super || root_path
    (location == root_path && App.count == 1) ? app_path(App.first) : location
  end

  protected

    def require_admin!
      redirect_to root_path unless user_signed_in? && current_user.admin?
    end

end

