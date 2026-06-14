# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery

  before_action :store_user_location!, if: :storable_location?
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :set_time_zone

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def require_admin!
    return if user_signed_in? && current_user.admin?

    flash[:error] = t("controllers.application.require_admin")

    redirect_to root_path
  end

  def set_time_zone
    Time.zone = current_user.time_zone if user_signed_in?
  end

  def authenticate_user_from_token!
    user_token = params[User.token_authentication_key].presence
    user = user_token && User.find_by(authentication_token: user_token)

    sign_in user, store: false if user
  end

  def user_not_authorized
    flash[:alert] = t("controllers.application.user_not_authorized")

    redirect_to root_path
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end
end
