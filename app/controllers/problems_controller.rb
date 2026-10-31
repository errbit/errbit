# frozen_string_literal: true

class ProblemsController < ApplicationController
  include ProblemsSearcher

  before_action :need_selected_problem, only: [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  def index
    load_problems_index
  end

  def show
    load_app_and_problem
    notice =
      if params[:notice_id]
        Notice.find(params.expect(:notice_id))
      else
        @notices = @problem.object.notices.reverse_ordered
          .page(params[:notice]).per(1)
        @notices.first
      end
    @notice = notice ? NoticeDecorator.new(notice) : nil
    @comment = Comment.new
  end

  def show_by_id
    problem = Problem.find(params.expect(:id))
    redirect_to app_problem_path(problem.app, problem)
  end

  def xhr_sparkline
    load_app_and_problem
    render partial: "problems/sparkline", locals: {problem: @problem}, layout: false
  end

  def close_issue
    load_app_and_problem
    issue = Issue.new(problem: @problem, user: current_user)

    flash[:error] = issue.errors.full_messages.join(", ") unless issue.close

    redirect_to app_problem_path(@app, @problem)
  end

  def create_issue
    load_app_and_problem
    issue = Issue.new(problem: @problem, user: current_user)

    issue.body = render_to_string(*issue.render_body_args)

    flash[:error] = issue.errors.full_messages.join(", ") unless issue.save

    redirect_to app_problem_path(@app, @problem)
  end

  def unlink_issue
    load_app_and_problem
    @problem.update_attribute(:issue_link, nil)

    redirect_to app_problem_path(@app, @problem)
  end

  def resolve
    load_app_and_problem
    @problem.resolve!

    flash[:success] = t(".the_error_has_been_resolved")

    redirect_back_or_to(root_path)
  end

  def resolve_several
    @selected_problems = selected_problems
    @selected_problems.each(&:resolve!)

    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, count: @selected_problems.count)} #{I18n.t("n_errs_have.been_resolved")}."

    redirect_back_or_to(root_path)
  end

  def unresolve_several
    @selected_problems = selected_problems
    @selected_problems.each(&:unresolve!)

    flash[:success] = "#{I18n.t(:n_errs_have, count: @selected_problems.count)} #{I18n.t("n_errs_have.been_unresolved")}."

    redirect_back_or_to(root_path)
  end

  def merge_several
    @selected_problems = selected_problems

    if @selected_problems.length < 2
      flash[:notice] = I18n.t("controllers.problems.flash.need_two_errors_merge")
    else
      ProblemMerge.new(@selected_problems).merge

      flash[:notice] = I18n.t("controllers.problems.flash.merge_several.success", nb: @selected_problems.count)
    end

    redirect_back_or_to(root_path)
  end

  def unmerge_several
    @selected_problems = selected_problems
    all = @selected_problems.flat_map(&:unmerge!)

    flash[:success] = "#{I18n.t(:n_errs_have, count: all.length)} #{I18n.t("n_errs_have.been_unmerged")}."

    redirect_back_or_to(root_path)
  end

  def destroy_several
    @selected_problems = selected_problems
    DestroyProblemsByIdJob.perform_later(selected_problems_ids)

    flash[:notice] = "#{I18n.t(:n_errs, count: @selected_problems.size)} #{I18n.t("n_errs.will_be_deleted")}."

    redirect_back_or_to(root_path)
  end

  def destroy_all
    @app = AppDecorator.new(App.find(params.expect(:app_id)))
    DestroyProblemsByAppJob.perform_later(@app.id)

    flash[:success] = "#{I18n.t(:n_errs, count: @app.problems.count)} #{I18n.t("n_errs.will_be_deleted")}."

    redirect_back_or_to(root_path)
  end

  def search
    load_problems_index

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: "problems/table", locals: {problems: @problems}, layout: false
        else
          render :index
        end
      end
    end
  end

  private

  def load_app_and_problem
    @app = AppDecorator.new(App.find(params.expect(:app_id)))
    @problem = ProblemDecorator.new(@app.problems.find(params.expect(:id)))
  end

  def load_problems_index
    @all_errs = params[:all_errs]
    @params_sort = params_sort
    @params_order = params_order
    @selected_problems = selected_problems
    @problems = find_problems
  end

  def app_scope
    params[:app_id] ? App.where(_id: params.expect(:app_id)) : App.all
  end

  def find_problems
    finder = Problem
      .for_apps(app_scope)
      .in_env(params[:environment])
      .filtered(params[:filter])
      .all_else_unresolved(@all_errs)
      .ordered_by(@params_sort, @params_order)

    finder = finder.search(params[:search]) if params[:search].present?
    finder.page(params[:page]).per(current_user.per_page)
  end

  def need_selected_problem
    return if err_ids.any?

    flash[:notice] = I18n.t("controllers.problems.flash.no_select_problem")

    redirect_back_or_to(root_path)
  end
end
