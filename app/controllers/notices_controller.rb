class NoticesController < ApplicationController
  skip_before_filter :authenticate_user!, :only => :create

  def create
    # params[:data] if the notice came from a GET request, raw_post if it came via POST
    @notice = App.report_error!(params[:data] || request.raw_post)
    render :xml => @notice.to_xml(:only => false, :methods => [:id])
  end

  # Redirects a notice to the problem page. Useful when using User Information at Airbrake gem.
  def locate
    problem = Notice.find(params[:id]).problem
    redirect_to app_err_path(problem.app, problem)
  end
end

