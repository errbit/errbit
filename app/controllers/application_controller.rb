class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :set_time_zone

  rescue_from ActionController::RedirectBackError, with: :redirect_to_root

  class StrongParametersWithEagerAttributesStrategy < DecentExposure::StrongParametersStrategy
    def assign_attributes?
      singular? && !get? && !delete? && (params[options[:param_key] || inflector.param_key]).present?
    end
  end

  decent_configuration do
    strategy StrongParametersWithEagerAttributesStrategy
  end

protected

  ##
  # Check if the current_user is admin or not and redirect to root url if not
  #
  def require_admin!
    return if user_signed_in? && current_user.admin?

    flash[:error] = "Sorry, you don't have permission to do that"
    redirect_to_root
  end

  def redirect_to_root
    redirect_to(root_path)
  end

  def set_time_zone
    Time.zone = current_user.time_zone if user_signed_in?
  end

  def authenticate_user_from_token!
    user_token = params[User.token_authentication_key].presence
    user       = user_token && User.find_by(authentication_token: user_token)

    sign_in user, store: false if user
  end
end
