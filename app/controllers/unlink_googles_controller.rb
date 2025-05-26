# frozen_string_literal: true

class UnlinkGooglesController < ApplicationController
  def update
    @user = User.find(params[:user_id])

    authorize @user

    @user.update!(google_uid: nil)

    flash[:success] = "Successfully unlinked #{@user.email} account!"

    redirect_to user_path(@user)
  end
end
