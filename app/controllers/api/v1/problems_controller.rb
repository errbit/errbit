class Api::V1::ProblemsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json, :xml

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  expose(:err) { Err.find(params[:id]) }
  expose(:problem) { err.problem }
  expose(:selected_problems) { Problem.where(id: params[:problems]) }

  def index
    problems = Problem.all

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.parse(params[:start_date]).utc
      end_date = Time.parse(params[:end_date]).utc
      problems = problems.in_date_range(start_date..end_date)
    end

    if params.key?(:app_id)
      problems = problems.where(app_id: params[:app_id])
    end

    if params[:open].to_s.downcase == "true"
      problems = problems.unresolved
    end

    presenter = ProblemPresenter
    if params[:comments].to_s.downcase == "true"
      problems = problems.includes(comments: :user)
      presenter = ProblemWithCommentsPresenter
    end

    respond_to do |format|
      format.html { render json: presenter.new(self, problems) } # render JSON if no extension specified on path
      format.json { render json: presenter.new(self, problems) }
      format.xml  { render xml:  presenter.new(self, problems).as_json }
    end
  end

  def changed
    begin
      since = Time.parse(params.fetch(:since)).utc
    rescue KeyError
      render json: { ok: false, message: "'since' is a required parameter" }, status: 400
      return
    rescue ArgumentError
      render json: { ok: false, message: "'since' must be an ISO8601 formatted timestamp" }, status: 400
      return
    end

    problems = Problem.with_deleted.changed_since(since)
    problems = problems.where(app_id: params[:app_id]) if params.key?(:app_id)
    presenter = ProblemWithDeletedPresenter

    respond_to do |format|
      format.html { render json: presenter.new(self, problems) } # render JSON if no extension specified on path
      format.json { render json: presenter.new(self, problems) }
      format.xml  { render xml:  presenter.new(self, problems).as_json }
    end
  end

  def resolve
    unless problem.resolved?
      err.comments.create!(body: params[:message]) if params[:message]
      problem.resolve!
    end
    head :ok
  end

  def unresolve
    problem.unresolve!
    head :ok
  end



  def merge_several
    if selected_problems.length < 2
      render json: I18n.t('controllers.problems.flash.need_two_errors_merge'), status: 422
    else
      count = selected_problems.count
      ProblemMerge.new(selected_problems).merge
      render json: I18n.t('controllers.problems.flash.merge_several.success', nb: count), status: 200
    end
  end

  def unmerge_several
    if selected_problems.length < 1
      render json: I18n.t('controllers.problems.flash.no_select_problem'), status: 422
    else
      all = selected_problems.map(&:unmerge!).flatten
      render json: "#{I18n.t(:n_errs_have, count: all.length)} been unmerged.", status: 200
    end
  end

  def destroy_several
    if selected_problems.length < 1
      render json: I18n.t('controllers.problems.flash.no_select_problem'), status: 422
    else
      nb_problem_destroy = ProblemDestroy.execute(selected_problems)
      render json: "#{I18n.t(:n_errs_have, count: nb_problem_destroy)} been deleted.", status: 200
    end
  end

end
