class AppsController < InheritedResources::Base

  before_filter :require_admin!, :except => [:index, :show]
  before_filter :parse_email_at_notices_or_set_default, :only => [:create, :update]
  respond_to :html

  def show
    respond_to do |format|
      format.html do
        @all_errs = !!params[:all_errs]

        @errs = resource.errs
        @errs = @errs.unresolved unless @all_errs
        @errs = @errs.in_env(params[:environment]).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)

        @deploys = @app.deploys.order_by(:created_at.desc).limit(5)
      end
      format.atom do
        @errs = resource.errs.unresolved.ordered
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
    plug_params(build_resource)
    new!
  end

  def edit
    plug_params(resource)
    edit!
  end

  protected
    def collection
      # Sort apps by number of unresolved errs, descending.
      # Caches the unresolved err counts while performing the sort.
      @unresolved_counts = {}
      @apps ||= end_of_association_chain.all.sort{|a,b|
        [a,b].each{|app| @unresolved_counts[app.id] ||= app.errs.unresolved.count }
        @unresolved_counts[b.id] <=> @unresolved_counts[a.id]
      }
    end

    def initialize_subclassed_issue_tracker
      if params[:app][:issue_tracker_attributes] && tracker_type = params[:app][:issue_tracker_attributes][:type]
        if IssueTracker.subclasses.map(&:name).concat(["IssueTracker"]).include?(tracker_type)
          @app.issue_tracker = tracker_type.constantize.new(params[:app][:issue_tracker_attributes])
        end
      end
    end

    def begin_of_association_chain
      # Filter the @apps collection to apps watched by the current user, unless user is an admin.
      # If user is an admin, then no filter is applied, and all apps are shown.
      current_user unless current_user.admin?
    end

    def interpolation_options
      {:app_name => resource.name}
    end

    def plug_params app
      app.watchers.build if app.watchers.none?
      app.issue_tracker = IssueTracker.new unless app.issue_tracker_configured?
      app.copy_attributes_from(params[:copy_attributes_from]) if params[:copy_attributes_from]
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

