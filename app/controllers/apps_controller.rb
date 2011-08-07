class AppsController < ApplicationController

  before_filter :require_admin!, :except => [:index, :show]
  before_filter :find_app, :except => [:index, :new, :create]
  before_filter :parse_email_at_notices_or_set_default, :only => [:create, :update]

  def index
    @apps = current_user.admin? ? App.all : current_user.apps.all
  end

  def show
    where_clause = {}
    respond_to do |format|
      format.html do
        where_clause[:environment] = params[:environment] if(params[:environment].present?)
        if(params[:all_errs])
          @errs = @app.errs.where(where_clause).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
          @all_errs = true
        else
          @errs = @app.errs.unresolved.where(where_clause).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
          @all_errs = false
        end
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

    # email_at_notices is edited as a string, and stored as an array.
    def parse_email_at_notices_or_set_default
      if params[:app] && val = params[:app][:email_at_notices]
        # Sanitize negative values, split on comma,
        # strip, parse as integer, remove all '0's.
        # If empty, set as default and show an error message.
        email_at_notices = val.gsub(/-\d+/,"").split(",").map{|v| v.strip.to_i }.reject{|v| v == 0}
        if email_at_notices.any?
          params[:app][:email_at_notices] = email_at_notices
        else
          default_array = params[:app][:email_at_notices] = Errbit::Config.email_at_notices
          flash[:error] = "Couldn't parse your notification frequency. Value was reset to default (#{default_array.join(', ')})."
        end
      end
    end
end

