class AppsController < ApplicationController
  
  def index
    @apps = App.all
  end
  
  def show
    @app = App.find(params[:id])
    @errs  = @app.errs.paginate
  end
  
  def new
    @app = App.new
    @app.watchers.build
  end
  
  def edit
    @app = App.find(params[:id])
    @app.watchers.build if @app.watchers.none?
  end
  
  def create
    @app = App.new(params[:app])
    
    if @app.save
      flash[:success] = 'Great success! Configure your app with the API key below'
      redirect_to app_path(@app)
    else
      render :new
    end
  end
  
  def update
    @app = App.find(params[:id])
    
    if @app.update_attributes(params[:app])
      flash[:success] = "Good news everyone! '#{@app.name}' was successfully updated."
      redirect_to app_path(@app)
    else
      render :edit
    end
  end
  
  def destroy
    @app = App.find(params[:id])
    @app.destroy
    flash[:success] = "'#{@app.name}' was successfully destroyed."
    redirect_to apps_path
  end
end
