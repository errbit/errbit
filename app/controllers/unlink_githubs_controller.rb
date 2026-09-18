# frozen_string_literal: true

class UnlinkGithubsController < ApplicationController
  def update
    @user = User.find(params.expect(:user_id))

    authorize @user

    @user.update!(github_login: nil, github_oauth_token: nil)

    flash[:success] = t("controllers.users.unlink_github.success", github_site_title: Errbit::Config.github_site_title)

    redirect_to user_path(@user)
  end
end
