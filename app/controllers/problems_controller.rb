##
# Manage problems
#
# List of actions available :
# MEMBER => :show, :edit, :update, :create, :destroy, :resolve, :unresolve, :create_issue, :unlink_issue
# COLLECTION => :index, :all, :destroy_several, :resolve_several, :unresolve_several, :merge_several, :unmerge_several, :search
class ProblemsController < ApplicationController
  include ProblemsSearcher

  before_action :need_selected_problem, only: [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  expose(:app_scope) do
    params[:app_id] ? App.where(_id: params[:app_id]) : App.all
  end

  expose(:app) do
    AppDecorator.new app_scope.find(params[:app_id])
  end

  expose(:problem) do
    ProblemDecorator.new app.problems.find(params[:id])
  end

  expose(:all_errs) do
    params[:all_errs]
  end

  expose(:params_environement) do
    params[:environment]
  end

  expose(:problems) do
    finder = Problem.
      for_apps(app_scope).
      in_env(params_environement).
      all_else_unresolved(all_errs).
      ordered_by(params_sort, params_order)

    finder = finder.search(params[:search]) if params[:search].present?
    finder.page(params[:page]).per(current_user.per_page)
  end

  def index; end

  def show
    @notices = problem.object.notices.reverse_ordered.
      page(params[:notice]).per(1)
    @notice  = NoticeDecorator.new @notices.first
    @comment = Comment.new
  end

  def close_issue
    issue = Issue.new(problem: problem, user: current_user)
    flash[:error] = issue.errors.full_messages.join(', ') unless issue.close

    redirect_to app_problem_path(app, problem)
  end

  def create_issue
    issue = Issue.new(problem: problem, user: current_user)
    issue.body = render_to_string(*issue.render_body_args)

    flash[:error] = issue.errors.full_messages.join(', ') unless issue.save

    redirect_to app_problem_path(app, problem)
  end

  def unlink_issue
    problem.update_attribute :issue_link, nil
    redirect_to app_problem_path(app, problem)
  end

  def resolve
    problem.resolve!
    flash[:success] = t('.the_error_has_been_resolved')
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(app)
  end

  def resolve_several
    selected_problems.each(&:resolve!)
    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, count: selected_problems.count)} #{I18n.t('n_errs_have.been_resolved')}."
    redirect_to :back
  end

  def unresolve_several
    selected_problems.each(&:unresolve!)
    flash[:success] = "#{I18n.t(:n_errs_have, count: selected_problems.count)} #{I18n.t('n_errs_have.been_unresolved')}."
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
      flash[:notice] = I18n.t('controllers.problems.flash.merge_several.success', nb: selected_problems.count)
    end
    redirect_to :back
  end

  def unmerge_several
    all = selected_problems.map(&:unmerge!).flatten
    flash[:success] = "#{I18n.t(:n_errs_have, count: all.length)} #{I18n.t('n_errs_have.been_unmerged')}."
    redirect_to :back
  end

  def destroy_several
    nb_problem_destroy = ProblemDestroy.execute(selected_problems)
    flash[:notice] = "#{I18n.t(:n_errs_have, count: nb_problem_destroy)} #{I18n.t('n_errs_have.been_deleted')}."
    redirect_to :back
  end

  def destroy_all
    nb_problem_destroy = ProblemDestroy.execute(app.problems)
    flash[:success] = "#{I18n.t(:n_errs_have, count: nb_problem_destroy)} #{I18n.t('n_errs_have.been_deleted')}."
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(app)
  end

  def search
    respond_to do |format|
      format.html { render :index }
      format.js
    end
  end

  ##
  # Redirect :back if no errors selected
  #
  protected def need_selected_problem
    return if err_ids.any?

    flash[:notice] = I18n.t('controllers.problems.flash.no_select_problem')
    redirect_to :back
  end
end
