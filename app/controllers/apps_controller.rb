class AppsController < InheritedResources::Base

  before_filter :require_admin!, :except => [:index, :show]
  before_filter :parse_email_at_notices_or_set_default, :only => [:create, :update]

  def show
    where_clause = {}
    respond_to do |format|
      format.html do
        where_clause[:environment] = params[:environment] if(params[:environment].present?)
        if(params[:all_errs])
          @errs = resource.errs.where(where_clause).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
          @all_errs = true
        else
          @errs = resource.errs.unresolved.where(where_clause).ordered.paginate(:page => params[:page], :per_page => current_user.per_page)
          @all_errs = false
        end
        @deploys = @app.deploys.order_by(:created_at.desc).limit(5)
      end
      format.atom do
        @errs = resource.errs.unresolved.ordered
      end
    end
  end

  def new
    build_resource.watchers.build
    @app.issue_tracker = IssueTracker.new
    new!
  end

  def edit
    resource.watchers.build if resource.watchers.none?
    resource.issue_tracker = IssueTracker.new if resource.issue_tracker.nil?
    edit!
  end

  def create
    create! :success => 'Great success! Configure your app with the API key below'
  end

  def update
    update! :success => "Good news everyone! '#{resource.name}' was successfully updated."
  end

  def destroy
    destroy! :success =>  "'#{resource.name}' was successfully destroyed."
  end

  protected
    def begin_of_association_chain
      current_user unless current_user.admin?
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

