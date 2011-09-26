class ErrsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_filter :find_app, :except => [:index, :all, :destroy_several, :resolve_several, :unresolve_several, :merge_several, :unmerge_several]
  before_filter :find_problem, :except => [:index, :all, :destroy_several, :resolve_several, :unresolve_several, :merge_several, :unmerge_several]
  before_filter :find_selected_problems, :only => [:destroy_several, :resolve_several, :unresolve_several, :merge_several, :unmerge_several]

  def index
    app_scope = current_user.admin? ? App.all : current_user.apps

    @sort = params[:sort]
    @sort = "last_notice_at" unless %w{app message last_notice_at last_deploy_at count}.member?(@sort)
    @order = params[:order] || "desc"

    @problems = Problem.for_apps(app_scope).in_env(params[:environment]).unresolved.ordered_by(@sort, @order)
    @selected_problems = params[:problems] || []
    respond_to do |format|
      format.html do
        @problems = @problems.paginate(:page => params[:page], :per_page => current_user.per_page)
      end
      format.atom
    end
  end

  def all
    app_scope = current_user.admin? ? App.all : current_user.apps
    @problems = Problem.for_apps(app_scope).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
    @selected_problems = params[:problems] || []
  end

  def show
    page      = (params[:notice] || @problem.notices_count)
    page      = 1 if page.to_i.zero?
    @notices  = @problem.notices.paginate(:page => page, :per_page => 1)
    @notice   = @notices.first
    @comment = Comment.new
  end

  def create_issue
    set_tracker_params

    if @app.issue_tracker
      @app.issue_tracker.create_issue @problem
    else
      flash[:error] = "This app has no issue tracker setup."
    end
    redirect_to app_err_path(@app, @problem)
  rescue ActiveResource::ConnectionError => e
    Rails.logger.error e.to_s
    flash[:error] = "There was an error during issue creation. Check your tracker settings or try again later."
    redirect_to app_err_path(@app, @problem)
  end

  def unlink_issue
    @problem.update_attribute :issue_link, nil
    redirect_to app_err_path(@app, @problem)
  end

  def resolve
    # Deal with bug in mongoid where find is returning an Enumberable obj
    @problem = @problem.first if @problem.respond_to?(:first)

    @problem.resolve!
    flash[:success] = 'Great news everyone! The err has been resolved.'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(@app)
  end

  def create_comment
    @comment = Comment.new(params[:comment].merge(:user_id => current_user.id))
    if @comment.valid?
      @problem.comments << @comment
      @problem.save
      flash[:success] = "Comment saved!"
    else
      flash[:error] = "I'm sorry, your comment was blank! Try again?"
    end
    redirect_to app_err_path(@app, @problem)
  end

  def destroy_comment
    @comment = Comment.find(params[:comment_id])
    if @comment.destroy
      flash[:success] = "Comment deleted!"
    else
      flash[:error] = "Sorry, I couldn't delete your comment for some reason. I hope you don't have any sensitive information in there!"
    end
    redirect_to app_err_path(@app, @problem)
  end


  def resolve_several
    @selected_problems.each(&:resolve!)
    flash[:success] = "Great news everyone! #{pluralize(@selected_problems.count, 'err has', 'errs have')} been resolved."
    redirect_to :back
  end

  def unresolve_several
    @selected_problems.each(&:unresolve!)
    flash[:success] = "#{pluralize(@selected_problems.count, 'err has', 'errs have')} been unresolved."
    redirect_to :back
  end

  def merge_several
    if @selected_problems.length < 2
      flash[:notice] = "You must select at least two errors to merge"
    else
      @merged_problem = Problem.merge!(@selected_problems)
      flash[:notice] = "#{@selected_problems.count} errors have been merged."
    end
    redirect_to :back
  end

  def unmerge_several
    all = @selected_problems.map(&:unmerge!).flatten
    flash[:success] = "#{pluralize(all.length, 'err has', 'errs have')} been unmerged."
    redirect_to :back
  end

  def destroy_several
    @selected_problems.each(&:destroy)
    flash[:notice] = "#{pluralize(@selected_problems.count, 'err has', 'errs have')} been deleted."
    redirect_to :back
  end

  protected
    def find_app
      @app = App.find(params[:app_id])

      # Mongoid Bug: could not chain: current_user.apps.find_by_id!
      # apparently finding by 'watchers.email' and 'id' is broken
      raise(Mongoid::Errors::DocumentNotFound.new(App,@app.id)) unless current_user.admin? || current_user.watching?(@app)
    end

    def find_problem
      @problem = @app.problems.find(params[:id])

      # Deal with bug in mogoid where find is returning an Enumberable obj
      @problem = @problem.first if @problem.respond_to?(:first)
    end

    def set_tracker_params
      IssueTracker.default_url_options[:host] = request.host
      IssueTracker.default_url_options[:port] = request.port
      IssueTracker.default_url_options[:protocol] = request.scheme
    end

    def find_selected_problems
      err_ids = (params[:problems] || []).compact
      if err_ids.empty?
        flash[:notice] = "You have not selected any errors"
        redirect_to :back
      else
        @selected_problems = Array(Problem.find(err_ids))
      end
    end
end

