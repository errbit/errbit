# frozen_string_literal: true

class UnlinkGooglesController < ApplicationController
  def update
    @user = User.find(params.expect(:user_id))

    authorize @user

    @user.update!(google_uid: nil)

    flash[:success] = t("controllers.users.unlink_google.success", email: @user.email)

    redirect_to user_path(@user)
  end
end
