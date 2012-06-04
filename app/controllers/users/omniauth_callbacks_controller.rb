class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    github_login = env["omniauth.auth"].extra.raw_info.login
    github_token = env["omniauth.auth"].credentials.token
    github_user  = User.where(:github_login => github_login).first

    # If user is already signed in, link github details to their account
    if current_user
      # ... unless a user is already registered with same github login
      if github_user && github_user != current_user
        flash[:error] = "User already registered with GitHub login '#{github_login}'!"
      else
        # Add github details to current user
        update_user_with_github_attributes(current_user, github_login, github_token)
        flash[:success] = "Successfully linked GitHub account!"
      end
      # User must have clicked 'link account' from their user page, so redirect there.
      redirect_to user_path(current_user)
    elsif github_user
      # Store OAuth token
      update_user_with_github_attributes(github_user, github_login, github_token)
      flash[:success] = I18n.t "devise.omniauth_callbacks.success", :kind => "GitHub"
      sign_in_and_redirect github_user, :event => :authentication
    else
      flash[:error] = "There are no authorized users with GitHub login '#{github_login}'. Please ask an administrator to register your user account."
      redirect_to new_user_session_path
    end
  end

  private

  def update_user_with_github_attributes(user, login, token)
    user.update_attributes(
      :github_login        => login,
      :github_oauth_token  => token
    )
  end
end
