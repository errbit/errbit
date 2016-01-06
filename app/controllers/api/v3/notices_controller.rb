class Api::V3::NoticesController < ApplicationController
  VERSION_TOO_OLD = 'Notice for old app version ignored'.freeze
  UNKNOWN_API_KEY = 'Your API key is unknown'.freeze

  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  respond_to :json

  def create
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'origin, content-type, accept'

    report = AirbrakeApi::V3::NoticeParser.new(
      params.merge(JSON.parse(request.raw_post) || {})).report

    return render text: UNKNOWN_API_KEY, status: 422 unless report.valid?
    return render text: VERSION_TOO_OLD, status: 422 unless report.should_keep?

    report.generate_notice!
    render status: 200, json: {
      id:  report.notice.id,
      url: report.problem.url
    }
  rescue AirbrakeApi::ParamsError
    render text: 'Invalid request', status: 400
  end
end
