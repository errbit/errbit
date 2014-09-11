class Api::V1::StatsController < ApplicationController
  respond_to :json, :xml

  # The stats API only requires an api_key for the given app.
  skip_before_filter :authenticate_user!
  before_filter :require_api_key_or_authenticate_user!

  def app
    if problem = @app.problems.order_by(:last_notice_at.desc).first
      @last_error_time = problem.last_notice_at
    end

    stats = {
      :name => @app.name,
      :id => @app.id,
      :last_error_time => @last_error_time,
      :unresolved_errors => @app.unresolved_count
    }

    respond_to do |format|
      format.any(:html, :json) { render :json => Yajl.dump(stats) } # render JSON if no extension specified on path
      format.xml  { render :xml  => stats }
    end
  end


  protected

  def require_api_key_or_authenticate_user!
    if params[:api_key].present?
      if @app = App.where(:api_key => params[:api_key]).first
        return true
      end
    end

    authenticate_user!
  end

end
