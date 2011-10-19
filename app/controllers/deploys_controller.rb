class DeploysController < ApplicationController

  protect_from_forgery :except => :create

  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :authenticate_user!, :only => :create

  def create
    @app = App.find_by_api_key!(params[:api_key])
    @deploy = @app.deploys.create!(default_deploy || heroku_deploy)
    render :xml => @deploy
  end

  def index
    # See AppsController#find_app for the reasoning behind this code.
    app = App.find(params[:app_id])
    raise Mongoid::Errors::DocumentNotFound.new(App, app.id) unless current_user.admin? || current_user.watching?(app)

    @deploys = Kaminari.paginate_array(app.deploys.order_by(:created_at.desc)).
      page(params[:page]).per(10)
    @app = app
  end

  private

    def default_deploy
      if params[:deploy]
        {
          :username     => params[:deploy][:local_username],
          :environment  => params[:deploy][:rails_env],
          :repository   => params[:deploy][:scm_repository],
          :revision     => params[:deploy][:scm_revision],
          :message      => params[:deploy][:message]
        }
      end
    end

    # handle Heroku's HTTP post deployhook format
    def heroku_deploy
      {
        :username     => params[:user],
        :environment  => params[:rack_env].try(:downcase) || params[:app],
        :repository   => "git@heroku.com:#{params[:app]}.git",
        :revision     => params[:head],
      }
    end

end

