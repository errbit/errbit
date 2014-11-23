class Api::V1::NoticesController < ApplicationController
  respond_to :json, :xml

  def index
    fields = %w{notices.id notices.created_at notices.message notices.error_class problems.app_id problems.app_name}
    notices = Notice.select(fields).joins(err: :problem)

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.parse(params[:start_date]).utc
      end_date = Time.parse(params[:end_date]).utc
      notices = notices.created_between(start_date, end_date)
    end

    results = benchmark("[api/v1/notices_controller] query time") { notices.all }

    respond_to do |format|
      format.html { render json: MultiJson.dump(results) } # render JSON if no extension specified on path
      format.json { render json: MultiJson.dump(results) }
      format.xml  { render xml:  results }
    end
  end

end
