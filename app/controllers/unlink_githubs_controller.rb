# frozen_string_literal: true

class UnlinkGithubsController < ApplicationController
  def update
    @user = User.find(params[:user_id])

    authorize @user

    @user.update!(github_login: nil, github_oauth_token: nil)

    redirect_to user_path(@user)
  end
end
