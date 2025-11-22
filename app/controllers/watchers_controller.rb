# frozen_string_literal: true

class WatchersController < ApplicationController
  def create
    app = Errbit::App.find(params[:app_id])

    app.watchers.create!(user: current_user)

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end

  def destroy
    app = Errbit::App.find(params[:app_id])

    watcher = app.watchers.find_by!(user: current_user)

    watcher.destroy!

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end
end
