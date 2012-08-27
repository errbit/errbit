class Api::V1::ProblemsController < ApplicationController
  respond_to :json, :xml
  
  def index
    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @problems = Problem.in_date_range(start_date..end_date)
    else
      @problems = Problem.all
    end
    
    respond_to do |format|
      format.html { render json: ProblemPresenter.new(@problems) } # render JSON if no extension specified on path
      format.json { render json: ProblemPresenter.new(@problems) }
      format.xml  { render xml: ProblemPresenter.new(@problems) }
    end
  end
  
end
