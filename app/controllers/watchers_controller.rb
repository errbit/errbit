class WatchersController < ApplicationController
  respond_to :html

  expose(:app) do
    App.find(params[:app_id])
  end

  expose(:watcher) do
    app.watchers.where(:user_id => params[:id]).first
  end

  before_filter :require_watcher_edit_priviledges, :only => [:update, :destroy]

  def update
    if watcher.nil?
      app.watchers.create(:user_id => params[:id])
      flash[:success] = I18n.t('controllers.watchers.flash.create.success', :app_name => app.name)
    end
    redirect_to app_path(app)
  end

  def destroy
    app.watchers.delete(watcher)
    flash[:success] = "That's sad. #{watcher.label} is no longer watcher."
    redirect_to app_path(app)
  end

  private

  def require_watcher_edit_priviledges
    redirect_to(root_path) unless current_user.id.to_s == params[:id] || current_user.admin?
  end

end

