class API::V1::StatsController < API::V1::ApiController
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
end
