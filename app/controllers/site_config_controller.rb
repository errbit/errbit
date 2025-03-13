class SiteConfigController < ApplicationController
  before_action :require_admin!

  def index
    @config = SiteConfig.document
  end

  def update
    SiteConfig.document.
      update(notice_fingerprinter: filtered_update_params.to_h)

    flash[:success] = "Updated site config"

    redirect_to action: :index
  end

private

  def filtered_update_params
    params.
      require(:site_config).
      require(:notice_fingerprinter_attributes).
      permit(
        :error_class,
        :message,
        :backtrace_lines,
        :component,
        :action,
        :environment_name)
  end
end
