# frozen_string_literal: true

class WatchersController < ApplicationController
  def update
    app = App.find(params[:app_id])

    app.watchers.create!(user: current_user)

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end

  def destroy
    app = App.find(params[:app_id])

    watcher = app.watchers.where(user_id: params[:id]).first

    app.watchers.delete(watcher)

    flash[:success] = t(".success", app: app.name)

    redirect_to app_path(app)
  end
end
