class ErrsController < ApplicationController

  before_filter :find_app, :except => [:index, :all]
  before_filter :find_err, :except => [:index, :all]

  def index
    app_scope = current_user.admin? ? App.all : current_user.apps
    respond_to do |format|
      format.html do
        @errs = Err.for_apps(app_scope).unresolved.ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
      end
      format.atom do
        @errs = Err.for_apps(app_scope).unresolved.ordered
      end
    end
  end

  def all
    app_scope = current_user.admin? ? App.all : current_user.apps
    @errs = Err.for_apps(app_scope).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
  end

  def show
    page      = (params[:notice] || @err.notices_count)
    page      = 1 if page.to_i.zero?
    @notices  = @err.notices.ordered.paginate(:page => page, :per_page => 1)
    @notice   = @notices.first
  end

  def create_issue
    set_tracker_params

    if @app.issue_tracker
      @app.issue_tracker.create_issue @err
    else
      flash[:error] = "This up has no issue tracker setup."
    end
    redirect_to app_err_path(@app, @err)
  rescue ActiveResource::ConnectionError => e
    Rails.logger.error e.to_s
    flash[:error] = "There was an error during issue creation. Check your tracker settings or try again later."
    redirect_to app_err_path(@app, @err)
  end

  def clear_issue
    @err.update_attribute :issue_link, nil
    redirect_to app_err_path(@app, @err)
  end

  def resolve
    # Deal with bug in mongoid where find is returning an Enumberable obj
    @err = @err.first if @err.respond_to?(:first)

    @err.resolve!

    flash[:success] = 'Great news everyone! The err has been resolved.'

    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(@app)
  end

  protected

    def find_app
      @app = App.find(params[:app_id])

      # Mongoid Bug: could not chain: current_user.apps.find_by_id!
      # apparently finding by 'watchers.email' and 'id' is broken
      raise(Mongoid::Errors::DocumentNotFound.new(App,@app.id)) unless current_user.admin? || current_user.watching?(@app)
    end

    def find_err
      @err = @app.errs.find(params[:id])
    end

    def set_tracker_params
      IssueTracker.default_url_options[:host] = request.host
      IssueTracker.default_url_options[:port] = request.port
      IssueTracker.default_url_options[:protocol] = request.scheme
    end

end
