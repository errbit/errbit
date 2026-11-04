# frozen_string_literal: true

class UnlinkOidcsController < ApplicationController
  def update
    @user = User.find(params.expect(:user_id))

    authorize @user

    @user.update!(oidc_uid: nil)

    flash[:success] = "Successfully unlinked #{@user.email} account!"

    redirect_to user_path(@user)
  end
end
