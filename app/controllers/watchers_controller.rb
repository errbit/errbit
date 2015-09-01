class WatchersController < ApplicationController
  respond_to :html

  expose(:app) do
    App.find(params[:app_id])
  end

  def destroy
    watcher = app.watchers.where(:user_id => params[:id]).first
    app.watchers.delete(watcher)
    flash[:success] = t('.success', app: app.name)
    redirect_to app_path(app)
  end

  def update
    app.watchers.create(user_id: current_user.id)
    flash[:success] = t('.success', app: app.name)
    redirect_to app_path(app)
  end
end
