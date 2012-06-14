class WatchersController < ApplicationController
  respond_to :html

  before_filter :find_watcher, :only => [:destroy]
  before_filter :require_watcher_edit_priviledges, :only => [:destroy]

  def destroy
    @app.watchers.delete(@watcher)
    flash[:success] = "That's sad. #{@watcher.label} is no longer watcher."
    redirect_to root_path
  end

  protected

    def find_watcher
      @app = App.find(params[:app_id])
      @watcher = @app.watchers.find(params[:id])
    end

    def require_watcher_edit_priviledges
      can_edit = current_user == @watcher.user || current_user.admin?
      redirect_to(root_path) and return(false) unless can_edit
    end

end

