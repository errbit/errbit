class WatchersController < ApplicationController
  expose :app
  expose :watchers, -> { app.watchers }

  def destroy
    watcher = watchers.where(user_id: params[:id]).first
    watchers.delete(watcher)
    flash[:success] = t(".success", app: app.name)
    redirect_to app_path(app)
  end

  def update
    watchers.create(user_id: current_user.id)
    flash[:success] = t(".success", app: app.name)
    redirect_to app_path(app)
  end
end
