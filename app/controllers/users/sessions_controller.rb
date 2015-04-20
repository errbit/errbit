class Users::SessionsController < Devise::SessionsController

  def new
    redirect_to user_omniauth_authorize_path(:gds)
  end

  private

  def after_sign_out_path_for(resource_name)
    GDS::SSO::Config.oauth_root_url + "/users/sign_out"
  end
end
