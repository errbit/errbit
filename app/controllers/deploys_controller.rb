class DeploysController < ApplicationController
  
  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :authenticate_user!, :only => :create
  
  def create
    @app = App.find_by_api_key!(params[:api_key])
    @deploy = @app.deploys.create!({
      :username     => params[:deploy][:local_username],
      :environment  => params[:deploy][:rails_env],
      :repository   => params[:deploy][:scm_repository],
      :revision     => params[:deploy][:scm_revision]
    })
    render :xml => @deploy
  end

  def index 
    app = current_user.apps.find(:conditions => {:name => params[:app_id]}).first

    @deploys = app.deploys.order_by(:created_at.desc)
  end
  
end
