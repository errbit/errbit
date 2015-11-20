class DeploysController < ApplicationController
  protect_from_forgery except: :create

  skip_before_action :verify_authenticity_token, only: :create
  skip_before_action :authenticate_user!, only: :create

  def create
    @app = App.find_by_api_key!(params[:api_key])
    @deploy = @app.deploys.create!(default_deploy || heroku_deploy)
    render xml: @deploy
  end

  def index
    @app = App.find(params[:app_id])
    @deploys = Kaminari.paginate_array(@app.deploys.order_by(:created_at.desc)).
      page(params[:page]).per(10)
  end

private

  def default_deploy
    return if params[:deploy].blank?

    {
      username:    params[:deploy][:local_username],
      environment: params[:deploy][:rails_env],
      repository:  params[:deploy][:scm_repository],
      revision:    params[:deploy][:scm_revision],
      message:     params[:deploy][:message]
    }
  end

  # handle Heroku's HTTP post deployhook format
  def heroku_deploy
    {
      username:    params[:user],
      environment: params[:rack_env].try(:downcase) || params[:app],
      repository:  "git@heroku.com:#{params[:app]}.git",
      revision:    params[:head]
    }
  end
end
