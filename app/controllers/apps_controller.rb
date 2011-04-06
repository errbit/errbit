class AppsController < ApplicationController

  before_filter :require_admin!, :except => [:index, :show]
  before_filter :find_app, :except => [:index, :new, :create]

  def index
    @apps = current_user.admin? ? App.all : current_user.apps.all
  end

  def show
    respond_to do |format|
      format.html do
        @errs = @app.errs.ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
        @deploys = @app.deploys.order_by(:created_at.desc).limit(5)
      end
      format.atom do
        @errs = @app.errs.unresolved.ordered
      end
    end
  end

  def new
    @app = App.new
    @app.watchers.build
    @app.issue_tracker = IssueTracker.new
  end

  def edit
    @app.watchers.build if @app.watchers.none?
    @app.issue_tracker = IssueTracker.new if @app.issue_tracker.nil?
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
    if @app.update_attributes(params[:app])
      flash[:success] = "Good news everyone! '#{@app.name}' was successfully updated."
      redirect_to app_path(@app)
    else
      render :edit
    end
  end

  def destroy
    @app.destroy
    flash[:success] = "'#{@app.name}' was successfully destroyed."
    redirect_to apps_path
  end

  protected

    def find_app
      @app = App.find(params[:id])

      # Mongoid Bug: could not chain: current_user.apps.find_by_id!
      # apparently finding by 'watchers.email' and 'id' is broken
      raise(Mongoid::Errors::DocumentNotFound.new(App,@app.id)) unless current_user.admin? || current_user.watching?(@app)
    end
end
