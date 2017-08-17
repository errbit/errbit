class WatchersController < ApplicationController
  expose :app
  expose :watcher
  expose :watchers, -> { app.watchers }

  def new; end

  def create
    watcher = Watcher.new(params.require(:watcher).permit(:user_id))

    if watcher.valid?
      app.watchers << watcher
      flash[:success] = t('.success')
      redirect_to app_path(app)
    else
      render :new
    end
  end

  def destroy
    if (params[:id] == current_user.id.to_s) || current_user.admin?
      watcher = watchers.where(user_id: params[:id]).first
      watchers.delete(watcher)
      flash[:success] = t('.success', app: app.name)
    else
      flash[:error] = t('flash.no_permission')
    end
    if current_user.admin? || Errbit::Config.restricted_access_mode.eql?(false)
      redirect_to app_path(app)
    else
      redirect_to_root
    end
  end

  def update
    watchers.create(user_id: current_user.id)
    flash[:success] = t('.success', app: app.name)
    redirect_to app_path(app)
  end
end
