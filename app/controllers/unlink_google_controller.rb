# frozen_string_literal: true

class UnlinkGoogleController < ApplicationController
  def update
    user = User.find(params[:user_id])

    authorize user

    user.update!(google_uid: nil)

    redirect_to user_path(user)
  end
end
