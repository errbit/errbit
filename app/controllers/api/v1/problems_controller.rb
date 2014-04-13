class Api::V1::ProblemsController < ApplicationController
  respond_to :json, :xml

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end
  
  expose(:err) { Err.find(params[:id]) }
  expose(:problem) { err.problem }

  def index
    problems = Problem.select %w{problems.id app_id app_name environment message problems.where first_notice_at last_notice_at resolved resolved_at notices_count}

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.parse(params[:start_date]).utc
      end_date = Time.parse(params[:end_date]).utc
      problems = problems.in_date_range(start_date..end_date)
    end

    results = benchmark("[api/v1/problems_controller] query time") { problems.to_a }

    respond_to do |format|
      format.html { render :json => MultiJson.dump(results) } # render JSON if no extension specified on path
      format.json { render :json => MultiJson.dump(results) }
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

end
