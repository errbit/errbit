class AppsController < InheritedResources::Base
  before_filter :require_admin!, :except => [:index, :show]
  before_filter :parse_email_at_notices_or_set_default, :only => [:create, :update]
  before_filter :parse_notice_at_notices_or_set_default, :only => [:create, :update]
  respond_to :html

  def show
    respond_to do |format|
      format.html do
        @all_errs = !!params[:all_errs]

        @sort  = params[:sort]
        @order = params[:order]
        @sort  = "last_notice_at" unless %w{message app last_deploy_at last_notice_at count}.member?(@sort)
        @order = "desc" unless %w{asc desc}.member?(@order)

        @problems = resource.problems
        @problems = @problems.unresolved unless @all_errs
        @problems = @problems.in_env(params[:environment]).ordered_by(@sort, @order).page(params[:page]).per(current_user.per_page)

        @selected_problems = params[:problems] || []
        @deploys = @app.deploys.order_by(:created_at.desc).limit(5)
      end
      format.atom do
        @problems = resource.problems.unresolved.ordered
      end
    end
  end

  def create
    @app = App.new(params[:app])
    initialize_subclassed_issue_tracker
    initialize_subclassed_notification_service
    create!
  end

  def update
    @app = resource
    initialize_subclassed_issue_tracker
    initialize_subclassed_notification_service
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
      @apps ||= end_of_association_chain.all.sort
    end

    def initialize_subclassed_issue_tracker
      # set the app's issue tracker
      if params[:app][:issue_tracker_attributes] && tracker_type = params[:app][:issue_tracker_attributes][:type]
        if IssueTracker.subclasses.map(&:name).concat(["IssueTracker"]).include?(tracker_type)
          @app.issue_tracker = tracker_type.constantize.new(params[:app][:issue_tracker_attributes])
        end
      end
    end

    def initialize_subclassed_notification_service
      # set the app's notification service
      if params[:app][:notification_service_attributes] && notification_type = params[:app][:notification_service_attributes][:type]
        if NotificationService.subclasses.map(&:name).concat(["NotificationService"]).include?(notification_type)
          @app.notification_service = notification_type.constantize.new(params[:app][:notification_service_attributes])
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
      app.notification_service = NotificationService.new unless app.notification_service_configured?
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

    def parse_notice_at_notices_or_set_default
      if params[:app][:notification_service_attributes] && val = params[:app][:notification_service_attributes][:notify_at_notices]
        # Sanitize negative values, split on comma,
        # strip, parse as integer, remove all '0's.
        # If empty, set as default and show an error message.
        notify_at_notices = val.gsub(/-\d+/,"").split(",").map{|v| v.strip.to_i }
        if notify_at_notices.any?
          params[:app][:notification_service_attributes][:notify_at_notices] = notify_at_notices
        else
          default_array = params[:app][:notification_service_attributes][:notify_at_notices] = Errbit::Config.notify_at_notices
          flash[:error] = "Couldn't parse your notification frequency. Value was reset to default (#{default_array.join(', ')})."
        end
      end
    end
end

