class Api::V1::ProblemsController < ApplicationController
  respond_to :json, :xml

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end
  
  expose(:err) { Err.find(params[:id]) }
  expose(:problem) { err.problem }
  expose(:selected_problems) { Problem.where(id: params[:problems]) }

  def index
    problems = Problem.select %w{problems.id app_id app_name environment message problems.where first_notice_at last_notice_at resolved resolved_at notices_count}

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.parse(params[:start_date]).utc
      end_date = Time.parse(params[:end_date]).utc
      problems = problems.in_date_range(start_date..end_date)
    end
    
    if params.key?(:app_id)
      problems = problems.where(app_id: params[:app_id])
    end
    
    if params[:open].to_s.downcase == "true"
      problems = problems.where(resolved_at: nil)
    end

    results = benchmark("[api/v1/problems_controller] query time") { problems.to_a }

    respond_to do |format|
      format.html { render :json => ProblemPresenter.new(self, results) } # render JSON if no extension specified on path
      format.json { render :json => ProblemPresenter.new(self, results) }
      format.xml  { render :xml  => results }
    end
  end
  
  def resolve
    problem.resolve!
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
      ProblemMerge.new(selected_problems).merge
      render json: I18n.t('controllers.problems.flash.merge_several.success', :nb => selected_problems.count), status: 200
    end
  end

  def unmerge_several
    if selected_problems.length < 1
      render json: I18n.t('controllers.problems.flash.no_select_problem'), status: 422
    else
      all = selected_problems.map(&:unmerge!).flatten
      render json: "#{I18n.t(:n_errs_have, :count => all.length)} been unmerged.", status: 200
    end
  end

  def destroy_several
    if selected_problems.length < 1
      render json: I18n.t('controllers.problems.flash.no_select_problem'), status: 422
    else
      nb_problem_destroy = ProblemDestroy.execute(selected_problems)
      render json: "#{I18n.t(:n_errs_have, :count => nb_problem_destroy)} been deleted.", status: 200
    end
  end

end
