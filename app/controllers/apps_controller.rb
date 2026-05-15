# frozen_string_literal: true

class AppsController < ApplicationController
  before_action :require_admin!, except: [:index, :show, :search]
  before_action :parse_email_at_notices_or_set_default, only: [:create, :update]
  before_action :parse_notice_at_notices_or_set_default, only: [:create, :update]

  helper_method :app_decorate, :apps, :app, :problems, :users, :all_errs, :params_sort, :params_order

  def index
  end

  def show
    app
  end

  def new
    @app = Errbit::App.new
    plug_params(@app)
  end

  def edit
    plug_params(app)
  end

  def create
    @app = Errbit::App.new

    process_fingerprinter_choice
    initialize_subclassed_notification_service

    @app.assign_attributes(app_params)

    if @app.save
      flash[:success] = I18n.t("controllers.apps.flash.create.success")

      redirect_to app_url(@app)
    else
      flash.now[:error] = I18n.t("controllers.apps.flash.create.error")

      render :new
    end
  end

  def update
    process_fingerprinter_choice
    initialize_subclassed_notification_service

    if app.update(app_params)
      flash[:success] = I18n.t("controllers.apps.flash.update.success")

      redirect_to app_url(app)
    else
      flash.now[:error] = I18n.t("controllers.apps.flash.update.error")

      render :edit
    end
  end

  def destroy
    if app.destroy
      flash[:success] = I18n.t("controllers.apps.flash.destroy.success")

      redirect_to apps_url
    else
      flash.now[:error] = I18n.t("controllers.apps.flash.destroy.error")

      render :show
    end
  end

  def regenerate_api_key
    app.regenerate_api_key!
    redirect_to edit_app_path(app)
  end

  def search
    respond_to do |format|
      format.html { render :index }
      format.js
    end
  end

  private

  def app
    @app ||= Errbit::App.find(params[:id])
  end

  def app_decorate
    @app_decorate ||= Errbit::AppDecorator.new(app)
  end

  def apps
    @apps ||= begin
      scope = params[:search].present? ? Errbit::App.search(params[:search]) : Errbit::App.all
      scope.to_a.sort.map { |a| Errbit::AppDecorator.new(a) }
    end
  end

  def all_errs
    params[:all_errs].present?
  end

  def problems
    @problems ||= if request.format == :atom
      app.problems.unresolved.ordered
    else
      pr = app.problems
      pr = pr.unresolved unless all_errs
      pr.in_env(params[:environment])
        .ordered_by(params_sort, params_order)
        .page(params[:page]).per(current_user.per_page)
    end
  end

  def users
    @users ||= Errbit::User.all.sort_by { |u| u.name.downcase }
  end

  def params_sort
    @params_sort ||= ["environment", "app", "message", "last_notice_at", "count"].include?(params[:sort]) ? params[:sort] : "last_notice_at"
  end

  def params_order
    @params_order ||= ["asc", "desc"].include?(params[:order]) ? params[:order] : "desc"
  end

  def initialize_subclassed_notification_service
    notification_type = params.dig(:app, :notification_service_attributes, :type)
    return if notification_type.blank?

    available_notification_classes = [Errbit::NotificationService] + Errbit::NotificationService.subclasses
    notification_class = available_notification_classes.detect { |c| c.name == notification_type }
    return if notification_class.nil?

    ns_params = params[:app][:notification_service_attributes].to_unsafe_h.except(:type)
    @app.notification_service = notification_class.new(ns_params)
  end

  def plug_params(app)
    app.watchers.build if app.watchers.none?
    app.issue_tracker ||= Errbit::IssueTracker.new
    app.notification_service = Errbit::NotificationService.new unless app.notification_service_configured?
    if app.notice_fingerprinter.nil?
      app.build_notice_fingerprinter(Errbit::SiteConfig.document.notice_fingerprinter_attributes)
    end
    app.copy_attributes_from(params[:copy_attributes_from]) if params[:copy_attributes_from]
  end

  # email_at_notices is edited as a string, and stored as an array.
  def parse_email_at_notices_or_set_default
    return if params[:app].blank?

    val = params[:app][:email_at_notices]
    return if val.blank?

    # Sanitize negative values, split on comma,
    # strip, parse as integer, remove all '0's.
    # If empty, set as default and show an error message.
    email_at_notices = val
      .gsub(/-\d+/, "")
      .split(",")
      .map { |v| v.strip.to_i }
      .reject { |v| v == 0 }

    if email_at_notices.any?
      params[:app][:email_at_notices] = email_at_notices
    else
      default_array = params[:app][:email_at_notices] = Errbit::Config.email_at_notices
      flash[:error] = "Couldn't parse your notification frequency. Value was reset to default (#{default_array.join(", ")})."
    end
  end

  def parse_notice_at_notices_or_set_default
    return if params[:app][:notification_service_attributes].blank?

    val = params[:app][:notification_service_attributes][:notify_at_notices]
    return if val.blank?

    notify_at_notices = val.gsub(/-\d+/, "").split(",").map { |v| v.strip.to_i }
    if notify_at_notices.any?
      params[:app][:notification_service_attributes][:notify_at_notices] = notify_at_notices
    else
      default_array = params[:app][:notification_service_attributes][:notify_at_notices] = Errbit::Config.notify_at_notices
      flash[:error] = "Couldn't parse your notification frequency. Value was reset to default (#{default_array.join(", ")})."
    end
  end

  def process_fingerprinter_choice
    return if params[:app].blank?

    if params[:app].delete(:use_site_fingerprinter) == "0"
      params[:app][:notice_fingerprinter_attributes] ||= {}
      params[:app][:notice_fingerprinter_attributes][:source] = Errbit::SiteConfig::CONFIG_SOURCE_APP
    else
      params[:app][:notice_fingerprinter_attributes] = Errbit::SiteConfig.document.notice_fingerprinter_attributes
    end
  end

  def app_params
    params.require(:app).permit!
  end
end
