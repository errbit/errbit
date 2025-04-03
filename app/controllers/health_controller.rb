# frozen_string_literal: true

class HealthController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def api_key_tester
    app = App.where(api_key: params[:api_key]).first
    is_good_result = app ? true : false
    response_status = is_good_result ? :ok : :forbidden
    render json: {ok: is_good_result}, status: response_status
  end
end
