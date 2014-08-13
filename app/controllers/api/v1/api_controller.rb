class API::V1::ApiController < ApplicationController
  respond_to :json, :xml

  # The stats API only requires an api_key for the given app.
  skip_before_filter :authenticate_user!
  before_filter :require_api_key_or_authenticate_user!
  
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
