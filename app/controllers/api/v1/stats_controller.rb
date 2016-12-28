class Api::V1::StatsController < ApplicationController
  respond_to :json, :xml

  # The stats API only requires an api_key for the given app.
  skip_before_action :authenticate_user!
  before_action :require_api_key_or_authenticate_user!

  def app
    query = {}
    if params.key?(:after_date)
      after_date = Time.zone.parse(params[:after_date]).utc
      query = { :created_at.gte => after_date }
    end

    if (problem = @app.problems.where(query).order_by(:last_notice_at.desc).first)
      @last_error_time = problem.last_notice_at
    end

    stats = {
      name:              @app.name,
      id:                @app.id,
      last_error_time:   @last_error_time,
      unresolved_errors: @app.unresolved_count(query),
      all_problems:      @app.problems_notices(query)
    }

    respond_to do |format|
      format.any(:html, :json) { render json: JSON.dump(stats) } # render JSON if no extension specified on path
      format.xml { render xml: stats }
    end
  end

  protected def require_api_key_or_authenticate_user!
    if params[:api_key].present?
      return true if (@app = App.where(api_key: params[:api_key]).first)
    end

    authenticate_user!
  end
end
