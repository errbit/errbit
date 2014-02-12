class Api::V1::ErrorsController < ApplicationController
  respond_to :json, :xml

  # The stats API only requires an api_key for the given app.
  skip_before_filter :authenticate_user!
  before_filter :require_api_key_or_authenticate_user!

  def app
    ps = @app.problems.filter(params[:env], params[:host], params[:query]).order_by(:last_notice_at.desc)
    problems = ps.page(0).per(20000)
    response = {
        "app" => @app.name,
        "environment" => params[:env],
        "host" => params[:host],
        "query" => params[:query],
        "notices" => problems
    }
    respond_to do |format|
      format.html { render :json => Yajl.dump(response) } # render JSON if no extension specified on path
      format.json { render :json => Yajl.dump(response) }
      format.xml  { render :xml  => response }
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


