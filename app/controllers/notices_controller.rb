class NoticesController < ApplicationController
  respond_to :xml

  skip_before_filter :authenticate_user!, :only => :create

  def create
    # params[:data] if the notice came from a GET request, raw_post if it came via POST
    report = ErrorReport.new(params[:data] || request.raw_post)

    if report.valid?
      report.generate_notice!
      api_xml = report.notice.to_xml(:only => false, :methods => [:id]) do |xml|
        xml.url locate_url(report.notice.id, :host => Errbit::Config.host)
      end
      render :xml => api_xml
    else
      render :text => "Your API key is unknown", :status => 422
    end
  end

  # Redirects a notice to the problem page. Useful when using User Information at Airbrake gem.
  def locate
    problem = Notice.find(params[:id]).problem
    redirect_to app_problem_path(problem.app, problem)
  end

end
