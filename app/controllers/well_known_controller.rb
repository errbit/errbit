# frozen_string_literal: true

class WellKnownController < ApplicationController
  def change_password
    redirect_to edit_user_path(current_user), status: :found
  end
end
