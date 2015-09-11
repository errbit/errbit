class AppsController < ApplicationController

  include ProblemsSearcher

  before_action :require_admin!, :except => [:index, :show]
  before_action :parse_email_at_notices_or_set_default, :only => [:create, :update]
  before_action :parse_notice_at_notices_or_set_default, :only => [:create, :update]
  respond_to :html

  expose(:app_scope) { App }

  expose(:apps) {
    app_scope.asc(:name).map { |app| AppDecorator.new(app) }
  }

  expose(:app, ancestor: :app_scope, attributes: :app_params)

  expose(:app_decorate) do
    AppDecorator.new(app)
  end

  expose(:all_errs) {
    !!params[:all_errs]
  }

  expose(:problems) {
    if request.format == :atom
      app.problems.unresolved.ordered
    else
      pr = app.problems
      pr = pr.unresolved unless all_errs
      pr.in_env(
        params[:environment]
      ).ordered_by(params_sort, params_order).page(params[:page]).per(current_user.per_page)
    end
  }

  expose(:deploys) {
    app.deploys.order_by(:created_at.desc).limit(5)
  }

  expose(:users) {
    User.all.sort_by {|u| u.name.downcase }
  }

  def index; end
  def show
    app
  end

  def new
    plug_params(app)
  end

  def create
    initialize_subclassed_notification_service
    if app.save
      redirect_to app_url(app), :flash => { :success => I18n.t('controllers.apps.flash.create.success') }
    else
      flash[:error] = I18n.t('controllers.apps.flash.create.error')
      render :new
    end
  end

  def update
    initialize_subclassed_notification_service
    if app.save
      redirect_to app_url(app), :flash => { :success => I18n.t('controllers.apps.flash.update.success') }
    else
      flash[:error] = I18n.t('controllers.apps.flash.update.error')
      render :edit
    end
  end

  def edit
    plug_params(app)
  end

  def destroy
    if app.destroy
      redirect_to apps_url, :flash => { :success => I18n.t('controllers.apps.flash.destroy.success') }
    else
      flash[:error] = I18n.t('controllers.apps.flash.destroy.error')
      render :show
    end
  end

  def regenerate_api_key
    app.regenerate_api_key!
    redirect_to edit_app_path(app)
  end

  protected

    def initialize_subclassed_notification_service
      # set the app's notification service
      if params[:app][:notification_service_attributes] && notification_type = params[:app][:notification_service_attributes][:type]
        available_notification_classes = [NotificationService] + NotificationService.subclasses
        notification_class = available_notification_classes.detect{|c| c.name == notification_type}
        if !notification_class.nil?
          app.notification_service = notification_class.new(params[:app][:notification_service_attributes])
        end
      end
    end

    def plug_params app
      app.watchers.build if app.watchers.none?
      app.issue_tracker ||= IssueTracker.new
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

  private
    def app_params
      params.require(:app).permit!
    end
end
