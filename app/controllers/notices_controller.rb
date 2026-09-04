# frozen_string_literal: true

class NoticesController < ApplicationController
  VERSION_TOO_OLD = "Notice for old app version ignored"
  UNKNOWN_API_KEY = "Your API key is unknown"
  XML_NOT_WELL_FORMED = "The provided XML was not well-formed"

  class ParamsError < StandardError
  end

  skip_before_action :authenticate_user!, only: :create
  skip_before_action :verify_authenticity_token, only: :create

  rescue_from ParamsError, with: :bad_params

  def create
    # params[:data] if the notice came from a GET request, raw_post if it came via POST
    report = ErrorReport.new(notice_params)

    if report.valid?
      if report.should_keep?
        report.generate_notice!
        api_xml = report.notice.to_xml(only: false, methods: [:id]) do |xml|
          xml.url locate_url(report.notice.id, host: Errbit::Config.host)
        end
        render xml: api_xml
      else
        render body: VERSION_TOO_OLD
      end
    else
      render body: UNKNOWN_API_KEY, status: :unprocessable_content
    end
  rescue Nokogiri::XML::SyntaxError
    render body: XML_NOT_WELL_FORMED, status: :unprocessable_content
  end

  # Redirects a notice to the problem page. Useful when using User Information at Airbrake gem.
  def locate
    problem = Notice.find(params.expect(:id)).problem
    redirect_to app_problem_path(problem.app, problem)
  end

  def show_by_id
    notice = Notice.find(params.expect(:id))
    problem = notice.problem
    redirect_to app_problem_path(problem.app, problem, notice_id: notice.id)
  end

  private

  def notice_params
    return @notice_params if @notice_params

    @notice_params = params[:data] || request.raw_post

    if @notice_params.blank?
      fail ParamsError, "Need a data params in GET or raw post data"
    end

    @notice_params
  end

  def bad_params(exception)
    render body: exception.message, status: :bad_request
  end
end
