class ErrsController < ApplicationController
  include ActionView::Helpers::TextHelper
  
  before_filter :find_app, :except => [:index, :all, :destroy_several, :merge_several, :resolve_several, :unmerge_several, :unresolve_several]
  before_filter :find_err, :except => [:index, :all, :destroy_several, :merge_several, :resolve_several, :unmerge_several, :unresolve_several]
  before_filter :find_selected_errs, :only => [:destroy_several, :merge_several, :resolve_several, :unmerge_several, :unresolve_several]
  
  
  
  def index
    app_scope = current_user.admin? ? App.all : current_user.apps
    @selected_errs = params[:errs] || []
    respond_to do |format|
      format.html do
        @errs = Problem.for_apps(app_scope).unresolved.ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
      end
      format.atom do
        @errs = Problem.for_apps(app_scope).unresolved.ordered
      end
    end
  end
  
  
  def all
    app_scope = current_user.admin? ? App.all : current_user.apps
    @errs = Problem.for_apps(app_scope).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
    @selected_errs = params[:errs] || []
  end
  
  
  def show
    page      = (params[:notice] || @err.notices.count)
    page      = 1 if page.to_i.zero?
    @notices  = @err.notices.paginate(:page => page, :per_page => 1)
    @notice   = @notices.first
  end
  
  
  def create_issue
    set_tracker_params
    
    if @app.issue_tracker
      @app.issue_tracker.create_issue @err
    else
      flash[:error] = "This up has no issue tracker setup."
    end
    redirect_to app_err_path(@app, @err)
  rescue ActiveResource::ConnectionError => e
    Rails.logger.error e.to_s
    flash[:error] = "There was an error during issue creation. Check your tracker settings or try again later."
    redirect_to app_err_path(@app, @err)
  end
  
  
  def clear_issue
    @err.update_attribute :issue_link, nil
    redirect_to app_err_path(@app, @err)
  end
  
  
  def resolve
    @err.resolve!
    flash[:success] = 'Great news everyone! The err has been resolved.'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(@app)
  end
  
  
  def resolve_several
    @selected_errs.each(&:resolve!)
    flash[:success] = "Great news everyone! #{pluralize(@selected_errs.count, 'err has', 'errs have')} been resolved."
    redirect_to :back
  end
  
  
  def unresolve_several
    @selected_errs.each(&:unresolve!)
    flash[:success] = "#{pluralize(@selected_errs.count, 'err has', 'errs have')} been unresolved."
    redirect_to :back
  end
  
  
  def merge_several
    if @selected_errs.length < 2
      flash[:notice] = "You must select at least two errors to merge"
    else
      @merged_problem = Problem.merge!(@selected_errs)
      flash[:notice] = "#{@selected_errs.count} errors have been merged."
    end
    redirect_to :back
  end
  
  
  def unmerge_several
    all = @selected_errs.map(&:unmerge!).flatten
    flash[:success] = "#{pluralize(all.length, 'err has', 'errs have')} been unmerged."
    redirect_to :back
  end
  
  
  def destroy_several
    @selected_errs.each(&:destroy)
    flash[:notice] = "#{pluralize(@selected_errs.count, 'err has', 'errs have')} been deleted."
    redirect_to :back
  end
  
  
protected
  
  
  def find_app
    @app = App.find(params[:app_id])
    
    # Mongoid Bug: could not chain: current_user.apps.find_by_id!
    # apparently finding by 'watchers.email' and 'id' is broken
    raise(Mongoid::Errors::DocumentNotFound.new(App,@app.id)) unless current_user.admin? || current_user.watching?(@app)
  end
  
  
  def find_err
    @err = @app.problems.find(params[:id])
    
    # Deal with bug in mogoid where find is returning an Enumberable obj
    @err = @err.first if @err.respond_to?(:first)
  end
  
  
  def find_selected_errs
    err_ids = (params[:errs] || []).compact
    if err_ids.empty?
      flash[:notice] = "You have not selected any errors"
      redirect_to :back
    else
      @selected_errs = Array(Problem.find(err_ids))
    end
  end
  
  
  def set_tracker_params
    IssueTracker.default_url_options[:host] = request.host
    IssueTracker.default_url_options[:port] = request.port
    IssueTracker.default_url_options[:protocol] = request.scheme
  end
  
  
end
