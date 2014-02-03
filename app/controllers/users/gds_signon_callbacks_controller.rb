class Users::GdsSignonCallbacksController < ApplicationController

  skip_before_filter :authenticate_user!
  before_filter :authenticate_api_user!

  def update
    oauth_hash = GDSBearerToken.omniauth_style_response(request.body)
    User.find_for_gds_oauth(oauth_hash)
    head :ok
  end

  def reauth
    user = User.where(:uid => params[:uid]).first
    user.set_remotely_signed_out! if user
    head :ok
  end

  private

  def authenticate_api_user!
    unless user_signed_in? and current_user.permissions.include?("user_update_permission")
      render :nothing => true, :status => 401
    end
  end
end
