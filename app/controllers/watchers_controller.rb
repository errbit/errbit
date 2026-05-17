# frozen_string_literal: true

class WatchersController < ApplicationController
  def create
    app = Errbit::App.find(params.expect(:app_id))

    app.watchers.create!(user: current_user)

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end

  def destroy
    app = Errbit::App.find(params.expect(:app_id))

    app.watchers.where(errbit_user_id: current_user.id).destroy_all

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end
end
