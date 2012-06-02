class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    github_login = request.env["omniauth.auth"].extra.raw_info.login
    github_token = request.env["omniauth.auth"].credentials.token
    github_user  = User.where(:github_login => github_login).first

    # If user is already signed in, link github details to their account
    if current_user
      # ... unless a user is already registered with same github login
      if github_user && github_user != current_user
        flash[:error] = "User already registered with Github login '#{github_login}'"
        redirect_to user_path(current_user)
      else
        # Add github details to current user
        current_user.update_attributes(
          :github_login       => github_login,
          :github_oauth_token => github_token
        )
        flash[:success] = "Successfully linked Github account!"
        redirect_to user_path(current_user)
      end

    elsif github_user
      # Store OAuth token
      @user.update_attribute :github_oauth_token, request.env["omniauth.auth"].credentials.token

      flash[:success] = I18n.t "devise.omniauth_callbacks.success", :kind => "Github"
      sign_in_and_redirect @user, :event => :authentication
    else
      redirect_to new_user_session_path
    end
  end
end
