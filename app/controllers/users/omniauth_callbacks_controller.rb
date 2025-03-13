class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github_auto_sign_up(github_token)
    return if Errbit::Config.github_org_id.nil?

    # See if the user is a member of the organization that we have access for
    # If they are, automatically create an account
    client = Octokit::Client.new(access_token: github_token)
    client.api_endpoint = Errbit::Config.github_api_url
    org_ids = client.organizations.map(&:id)
    return unless org_ids.include?(Errbit::Config.github_org_id)

    user_email = github_get_user_email(client)
    if user_email.nil?
      flash[:error] = "Could not retrieve user's email from GitHub"
      nil
    else
      User.create(name: request.env["omniauth.auth"].extra.raw_info.name, email: user_email)
    end
  end

  def github
    github_login = request.env["omniauth.auth"].extra.raw_info.login
    github_token = request.env["omniauth.auth"].credentials.token
    github_site_title = Errbit::Config.github_site_title
    github_user = User.where(github_login: github_login).first || github_auto_sign_up(github_token)

    # If user is already signed in, link github details to their account
    if current_user
      # ... unless a user is already registered with same github login
      if github_user && github_user != current_user
        flash[:error] = "User already registered with #{github_site_title} login '#{github_login}'!"
      else
        # Add github details to current user
        update_user_with_github_attributes(current_user, github_login, github_token)
        flash[:success] = "Successfully linked #{github_site_title} account!"
      end
      # User must have clicked 'link account' from their user page, so redirect there.
      redirect_to user_path(current_user)
    elsif github_user
      # Store OAuth token
      update_user_with_github_attributes(github_user, github_login, github_token)
      flash[:success] = I18n.t "devise.omniauth_callbacks.success", kind: github_site_title
      sign_in_and_redirect github_user, event: :authentication
    elsif flash[:error]
      redirect_to new_user_session_path
    else
      flash[:error] = "There are no authorized users with #{github_site_title} login '#{github_login}'. Please ask an administrator to register your user account."
      redirect_to new_user_session_path
    end
  end

  def google_oauth2
    google_uid = request.env["omniauth.auth"].uid
    google_email = request.env["omniauth.auth"].info.email
    google_user = User.where(google_uid: google_uid).first
    google_site_title = Errbit::Config.google_site_title
    # If user is already signed in, link google details to their account
    if current_user
      # ... unless a user is already registered with same google login
      if google_user && google_user != current_user
        flash[:error] = "User already registered with #{google_site_title} login '#{google_email}'!"
      else
        # Add google details to current user
        current_user.update(google_uid: google_uid)
        flash[:success] = "Successfully linked #{google_email} account!"
      end
      # User must have clicked 'link account' from their user page, so redirect there.
      redirect_to user_path(current_user)
    elsif google_user
      flash[:success] = I18n.t "devise.omniauth_callbacks.success", kind: google_site_title
      sign_in_and_redirect google_user, event: :authentication
    elsif Errbit::Config.google_auto_provision
      if User.valid_google_domain?(google_email)
        user = User.create_from_google_oauth2(request.env["omniauth.auth"])
        if user.persisted?
          flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: google_site_title
          sign_in_and_redirect user, event: :authentication
        else
          session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
          redirect_to new_user_session_path, alert: user.errors.full_messages.join("\n")
        end
      else
        flash[:error] = I18n.t "devise.google_login.domain_unauthorized"
        redirect_to new_user_session_path
      end
    else
      flash[:error] = "There are no authorized users with #{google_site_title} login '#{google_email}'. Please ask an administrator to register your user account."
      redirect_to new_user_session_path
    end
  end

  private

  def update_user_with_github_attributes(user, login, token)
    user.update(
      github_login: login,
      github_oauth_token: token
    )
  end

  def github_get_user_email(client)
    email = nil
    begin
      email = client.emails.select(&:primary).first
      return email.email unless email.nil?

      email = client.emails.first
      return email.email unless email.nil?
    rescue Octokit::ClientError => e
      Rails.logger.warn "Octokit:ClientError exception while retrieving user's emails. We probably lack user:email permission. Will try to extract email from user's public profile. Error message: #{e}"
    end

    # Try to get email from public profile
    if request.env["omniauth.auth"].extra.raw_info.email.present?
      return request.env["omniauth.auth"].extra.raw_info.email
    end

    nil
  end
end
