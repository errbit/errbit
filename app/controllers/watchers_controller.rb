class WatchersController < ApplicationController
  respond_to :html

  expose(:app) do
    App.find(params[:app_id])
  end

  expose(:watcher) do
    app.watchers.where(:user_id => params[:id]).first
  end

  before_filter :require_watcher_edit_priviledges, :only => [:destroy]

  def destroy
    app.watchers.delete(watcher)
    flash[:success] = "That's sad. #{watcher.label} is no longer watcher."
    redirect_to root_path
  end

  private

  def require_watcher_edit_priviledges
    redirect_to(root_path) unless current_user == watcher.user || current_user.admin?
  end

end

