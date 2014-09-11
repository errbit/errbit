class Api::V1::ProblemsController < ApplicationController
  respond_to :json, :xml
  FIELDS = %w{app_id app_name environment message where first_notice_at last_notice_at resolved resolved_at notices_count}

  def show
    result = benchmark("[api/v1/problems_controller/show] query time") do
      begin
        Problem.only(FIELDS).find(params[:id])
      rescue Mongoid::Errors::DocumentNotFound
        head :not_found
        return false
      end
    end

    respond_to do |format|
      format.any(:html, :json) { render :json => result } # render JSON if no extension specified on path
      format.xml  { render :xml  => result }
    end
  end

  def index
    query = {}

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.parse(params[:start_date]).utc
      end_date = Time.parse(params[:end_date]).utc
      query = {:first_notice_at=>{"$lte"=>end_date}, "$or"=>[{:resolved_at=>nil}, {:resolved_at=>{"$gte"=>start_date}}]}
    end

    results = benchmark("[api/v1/problems_controller/index] query time") do
      Problem.where(query).with(:consistency => :strong).only(FIELDS).to_a
    end

    respond_to do |format|
      format.any(:html, :json) { render :json => Yajl.dump(results) } # render JSON if no extension specified on path
      format.xml  { render :xml  => results }
    end
  end

end
