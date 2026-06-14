# frozen_string_literal: true

class WellKnownController < ApplicationController
  skip_before_action :authenticate_user!

  def change_password
    if user_signed_in?
      redirect_to edit_user_path(current_user), status: :found
    else

    end
  end
end
