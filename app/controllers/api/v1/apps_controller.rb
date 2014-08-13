class API::V1::AppsController < API::V1::ApiController
  def index
    @apps = App.all
  end

  def show
    @app = App.find(params[:id])
  end
end
