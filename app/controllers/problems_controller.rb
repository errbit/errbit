# frozen_string_literal: true

class ProblemsController < ApplicationController
  before_action :need_selected_problem, only: [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  helper_method :app, :problem, :problems, :all_errs, :filter,
    :params_environment, :params_sort, :params_order,
    :selected_problems, :selected_problems_ids, :err_ids

  def index
  end

  def show
    notice = if params[:notice_id]
      Errbit::Notice.find(params.expect(:notice_id))
    else
      # `notices` is pre-ordered ASC for callers like recache; use `.reorder`
      # to override (AR appends order clauses instead of replacing).
      @notices = problem.object.notices.reorder(created_at: :desc)
        .page(params[:notice]).per(1)
      @notices.first
    end

    @notice = notice ? Errbit::NoticeDecorator.new(notice) : nil
    @comment = Errbit::Comment.new
  end

  def show_by_id
    record = Errbit::Problem.find(params.expect(:id))
    redirect_to app_problem_path(record.app, record)
  end

  def xhr_sparkline
    render partial: "problems/sparkline", locals: {problem: problem}, layout: false
  end

  def close_issue
    issue = Errbit::Issue.new(problem: problem, user: current_user)

    flash[:error] = issue.errors.full_messages.join(", ") unless issue.close

    redirect_to app_problem_path(app, problem)
  end

  def create_issue
    issue = Errbit::Issue.new(problem: problem, user: current_user)

    issue.body = render_to_string(*issue.render_body_args)

    flash[:error] = issue.errors.full_messages.join(", ") unless issue.save

    redirect_to app_problem_path(app, problem)
  end

  def unlink_issue
    problem.update(issue_link: nil)

    redirect_to app_problem_path(app, problem)
  end

  def resolve
    problem.resolve!

    flash[:success] = t(".the_error_has_been_resolved")

    redirect_back_or_to(root_path)
  end

  def resolve_several
    selected_problems.each(&:resolve!)

    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, count: selected_problems.count)} #{I18n.t("n_errs_have.been_resolved")}."

    redirect_back_or_to(root_path)
  end

  def unresolve_several
    selected_problems.each(&:unresolve!)

    flash[:success] = "#{I18n.t(:n_errs_have, count: selected_problems.count)} #{I18n.t("n_errs_have.been_unresolved")}."

    redirect_back_or_to(root_path)
  end

  def merge_several
    if selected_problems.length < 2
      flash[:notice] = I18n.t("controllers.problems.flash.need_two_errors_merge")
    else
      Errbit::ProblemMerge.new(selected_problems).merge

      flash[:notice] = I18n.t("controllers.problems.flash.merge_several.success", nb: selected_problems.count)
    end

    redirect_back_or_to(root_path)
  end

  def unmerge_several
    all = selected_problems.flat_map(&:unmerge!)

    flash[:success] = "#{I18n.t(:n_errs_have, count: all.length)} #{I18n.t("n_errs_have.been_unmerged")}."

    redirect_back_or_to(root_path)
  end

  def destroy_several
    Errbit::DestroyProblemsByIdJob.perform_later(selected_problems_ids)

    flash[:notice] = "#{I18n.t(:n_errs, count: selected_problems.size)} #{I18n.t("n_errs.will_be_deleted")}."

    redirect_back_or_to(root_path)
  end

  def destroy_all
    Errbit::DestroyProblemsByAppJob.perform_later(app.id)

    flash[:success] = "#{I18n.t(:n_errs, count: app.problems.count)} #{I18n.t("n_errs.will_be_deleted")}."

    redirect_back_or_to(root_path)
  end

  def search
    respond_to do |format|
      format.html { render :index }
      format.js
    end
  end

  # Helper-method-exposed accessors. Kept public so controller specs that read
  # `controller.app`, `controller.problems`, etc. continue to work (mirroring
  # the previous decent_exposure behavior).

  def app_scope
    @app_scope ||= params[:app_id] ? Errbit::App.where(id: params.expect(:app_id)) : Errbit::App.all
  end

  def app
    @app ||= Errbit::AppDecorator.new(app_scope.find(params.expect(:app_id)))
  end

  def problem
    @problem ||= Errbit::ProblemDecorator.new(app.problems.find(params.expect(:id)))
  end

  def all_errs
    params[:all_errs]
  end

  def filter
    params[:filter]
  end

  def params_environment
    params[:environment]
  end

  def params_sort
    @params_sort ||= ["environment", "app", "message", "last_notice_at", "count"].include?(params[:sort]) ? params[:sort] : "last_notice_at"
  end

  def params_order
    @params_order ||= ["asc", "desc"].include?(params[:order]) ? params[:order] : "desc"
  end

  def err_ids
    @err_ids ||= (params[:problems] || []).compact
  end

  def selected_problems
    @selected_problems ||= Array(Errbit::Problem.where(id: err_ids))
  end

  def selected_problems_ids
    selected_problems.map { |p| p.id.to_s }
  end

  # To use with_app_exclusions, hit a path like
  # /problems?filter=-app:noisy_app%20-app:another_noisy_app — useful when
  # there are noisy apps that should be ignored.
  def problems
    @problems ||= begin
      finder = Errbit::Problem
        .for_apps(app_scope)
        .in_env(params_environment)
        .filtered(filter)
        .all_else_unresolved(all_errs)
        .ordered_by(params_sort, params_order)
      finder = finder.search(params[:search]) if params[:search].present?
      finder.page(params[:page]).per(current_user.per_page)
    end
  end

  private

  def need_selected_problem
    return if err_ids.any?

    flash[:notice] = I18n.t("controllers.problems.flash.no_select_problem")

    redirect_back_or_to(root_path)
  end
end
