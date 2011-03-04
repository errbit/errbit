class ErrsController < ApplicationController
  
  before_filter :find_app, :except => [:index, :all]
  
  def index
    app_scope = current_user.admin? ? App.all : current_user.apps
    @errs = Err.for_apps(app_scope).unresolved.ordered.paginate(:page => params[:page], :per_page => Err.per_page)
  end
  
  def all
    app_scope = current_user.admin? ? App.all : current_user.apps
    @errs = Err.for_apps(app_scope).ordered.paginate(:page => params[:page], :per_page => Err.per_page)
  end
  
  def show
    @err      = @app.errs.find(params[:id])
    page      = (params[:notice] || @err.notices.count)
    page      = 1 if page.to_i.zero?
    @notices  = @err.notices.ordered.paginate(:page => page, :per_page => 1)
    @notice   = @notices.first
  end
  
  def resolve
    @err  = @app.errs.find(params[:id])
    
    # Deal with bug in mogoid where find is returning an Enumberable obj
    @err = @err.first if @err.respond_to?(:first)
    
    @err.resolve!
    
    flash[:success] = 'Great news everyone! The err has been resolved.'

    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(@app)
  end
  
  protected
  
    def find_app
      @app = App.find(params[:app_id])
      
      # Mongoid Bug: could not chain: current_user.apps.find_by_id!
      # apparently finding by 'watchers.email' and 'id' is broken
      raise(Mongoid::Errors::DocumentNotFound.new(App,@app.id)) unless current_user.admin? || current_user.watching?(@app)
    end
  
end
