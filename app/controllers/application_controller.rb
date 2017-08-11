class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :require_right!
  before_action :set_time_zone

  rescue_from ActionController::RedirectBackError, with: :redirect_to_root

protected

  ##
  # Check if the current_user is admin or not and redirect to root url if not
  #
  def require_admin!
    return if user_signed_in? && current_user.admin?

    flash[:error] = t('flash.no_permission')
    redirect_to_root
  end

  def require_right!
    return if (current_user.present? && current_user.admin?) || Errbit::Config.restricted_access_mode.eql?(false)

    app_id = params[:id] if params[:controller].present? && params[:controller] == 'apps'
    app_id ||= params[:app_id] if params[:controller].present? && %w(notices comments problems watchers).include?(params[:controller])

    return if app_id.blank?
    return if app_right?(app_id)

    flash[:error] = t('flash.no_permission')
    redirect_to_root
  end

  def app_right?(app_id)
    App.find(app_id).watchers.map { |x| x.user == current_user }.include? true
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
