# frozen_string_literal: true

class WatchController < ApplicationController
  def create
    app = App.find(params[:app_id])

    app.watchers.create!(user: current_user)

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end

  def destroy
    app = App.find(params[:app_id])

    watcher = app.watchers.where(user: current_user).first

    app.watchers.delete(watcher)

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end
end
