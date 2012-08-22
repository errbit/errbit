class Api::V1::ProblemsController < ApplicationController
  
  def index
    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @problems = Problem.in_date_range(start_date..end_date)
    else
      @problems = Problem.all
    end
  end
  
end
