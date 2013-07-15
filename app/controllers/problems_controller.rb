##
# Manage problems
#
# List of actions available :
# MEMBER => :show, :edit, :update, :create, :destroy, :resolve, :unresolve, :create_issue, :unlink_issue
# COLLECTION => :index, :all, :destroy_several, :resolve_several, :unresolve_several, :merge_several, :unmerge_several, :search
class ProblemsController < ApplicationController

  before_filter :set_sorting_params, :only => [:index, :all, :search]
  before_filter :set_tracker_params, :only => [:create_issue]

  before_filter :need_selected_problem, :only => [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  expose(:app) {
    if current_user.admin?
      App.find(params[:app_id])
    else
      current_user.apps.find(params[:app_id])
    end
  }

  expose(:problem) {
    app.problems.find(params[:id])
  }

  expose(:err_ids) {
    (params[:problems] || []).compact
  }

  expose(:selected_problems) {
    Array(Problem.find(err_ids))
  }

  def index
    app_scope = current_user.admin? ? App.all : current_user.apps
    @all_errs = params[:all_errs]
    @problems = Problem.for_apps(app_scope).in_env(params[:environment]).all_else_unresolved(@all_errs).ordered_by(@sort, @order)
    respond_to do |format|
      format.html do
        @problems = @problems.page(params[:page]).per(current_user.per_page)
      end
      format.atom
    end
  end

  def show
    @notices  = problem.notices.reverse_ordered.page(params[:notice]).per(1)
    @notice   = @notices.first
    @comment = Comment.new
  end

  def create_issue
    issue_creation = IssueCreation.new(problem, current_user, params[:tracker])

    unless issue_creation.execute
      flash[:error] = issue_creation.errors[:base].first
    end

    redirect_to app_problem_path(app, problem)
  end

  def unlink_issue
    problem.update_attribute :issue_link, nil
    redirect_to app_problem_path(app, problem)
  end

  def resolve
    problem.resolve!
    flash[:success] = 'Great news everyone! The err has been resolved.'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(app)
  end

  def resolve_several
    selected_problems.each(&:resolve!)
    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, :count => selected_problems.count)} been resolved."
    redirect_to :back
  end

  def unresolve_several
    selected_problems.each(&:unresolve!)
    flash[:success] = "#{I18n.t(:n_errs_have, :count => selected_problems.count)} been unresolved."
    redirect_to :back
  end

  ##
  # Action to merge several Problem in One problem
  #
  # @param [ Array<String> ] :problems the list of problem ids
  #
  def merge_several
    if selected_problems.length < 2
      flash[:notice] = I18n.t('controllers.problems.flash.need_two_errors_merge')
    else
      ProblemMerge.new(selected_problems).merge
      flash[:notice] = I18n.t('controllers.problems.flash.merge_several.success', :nb => selected_problems.count)
    end
    redirect_to :back
  end

  def unmerge_several
    all = selected_problems.map(&:unmerge!).flatten
    flash[:success] = "#{I18n.t(:n_errs_have, :count => all.length)} been unmerged."
    redirect_to :back
  end

  def destroy_several
    nb_problem_destroy = ProblemDestroy.execute(selected_problems)
    flash[:notice] = "#{I18n.t(:n_errs_have, :count => nb_problem_destroy)} been deleted."
    redirect_to :back
  end

  def search
    if params[:app_id]
      app_scope = App.where(:_id => params[:app_id])
    else
      app_scope = current_user.admin? ? App.all : current_user.apps
    end
    @problems = Problem.search(params[:search]).for_apps(app_scope).in_env(params[:environment]).all_else_unresolved(params[:all_errs]).ordered_by(@sort, @order)
    @selected_problems = params[:problems] || []
    @problems = @problems.page(params[:page]).per(current_user.per_page)
    render :content_type => 'text/javascript'
  end

  protected

    def set_tracker_params
      IssueTracker.default_url_options[:host] = request.host
      IssueTracker.default_url_options[:port] = request.port
      IssueTracker.default_url_options[:protocol] = request.scheme
    end

    def set_sorting_params
      @sort = params[:sort]
      @sort = "last_notice_at" unless %w{app message last_notice_at last_deploy_at count}.member?(@sort)
      @order = params[:order] || "desc"
    end

  ##
  # Redirect :back if no errors selected
  #
  def need_selected_problem
    if err_ids.empty?
      flash[:notice] = I18n.t('controllers.problems.flash.no_select_problem')
      redirect_to :back
    end
  end
end

