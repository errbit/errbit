module BadgesHelper
  def badge_path(app, badge_type)
    path_params = { badge_type: badge_type, format: 'svg' }
    unless Errbit::Config.badge_public
      path_params[User.token_authentication_key] = current_user.authentication_token
    end
    badge_app_url(app, path_params)
  end
end
