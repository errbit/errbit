class AppsController < InheritedResources::Base

  before_filter :require_admin!, :except => [:index, :show]
  before_filter :parse_email_at_notices_or_set_default, :only => [:create, :update]
  respond_to :html

  def show
    where_clause = {}
    respond_to do |format|
      format.html do
        where_clause["errs.environment"] = params[:environment] if(params[:environment].present?)
        if(params[:all_errs])
          @errs = resource.problems.where(where_clause).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
          @all_errs = true
        else
          @errs = resource.problems.unresolved.where(where_clause).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
          @all_errs = false
        end
        @selected_errs = params[:errs] || []
        @deploys = @app.deploys.order_by(:created_at.desc).limit(5)
      end
      format.atom do
        @errs = resource.problems.unresolved.ordered
      end
    end
  end

  def create
    @app = App.new(params[:app])
    initialize_subclassed_issue_tracker
    create!
  end

  def update
    @app = resource
    initialize_subclassed_issue_tracker
    update!
  end

  def new
    plug_params build_resource
    new!
  end

  def edit
    plug_params resource
    edit!
  end


  protected
    def initialize_subclassed_issue_tracker
      if params[:app][:issue_tracker_attributes] && tracker_type = params[:app][:issue_tracker_attributes][:type]
        if IssueTracker.subclasses.map(&:to_s).include?(tracker_type.to_s)
          @app.issue_tracker = tracker_type.constantize.new(params[:app][:issue_tracker_attributes])
        end
      end
    end

    def begin_of_association_chain
      current_user unless current_user.admin?
    end

    def interpolation_options
      {:app_name => resource.name}
    end

    def plug_params app
      app.watchers.build if app.watchers.none?
      app.issue_tracker = IssueTracker.new unless app.issue_tracker_configured?
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

