class Api::V3::NoticesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  respond_to :json

  def create
    params.merge!(JSON.parse(request.raw_post) || {})
    report = AirbrakeApi::V3::NoticeParser.new(params).report

    if report.valid?
      if report.should_keep?
        report.generate_notice!
        render json: {
          id: report.notice.id,
          url: app_problem_url(
            report.app,
            report.error.problem_id)
        }
      else
        render text: 'Notice for old app version ignored'
      end
    else
      render text: 'Your API key is unknown', status: 422
    end
  rescue AirbrakeApi::ParamsError
    render text: 'Invalid request', status: 400
  end
end
