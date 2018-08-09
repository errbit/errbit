class HealthController < ActionController::Base
  def readiness
    check_results = [run_mongo_check]
    all_ok = check_results.all? do |check|
      check[:ok]
    end
    response_status = all_ok ? :ok : :error
    render json: { ok: all_ok, details: check_results }, status: response_status
  end

  def liveness
    render json: { ok: true }, status: :ok
  end

  def api_key_tester
    app = App.where(api_key: params[:api_key]).first
    is_good_result = app ? true : false
    response_status = is_good_result ? :ok : :forbidden
    render json: { ok: is_good_result }, status: response_status
  end

private

  def run_mongo_check
    # collections might be empty which is ok but it will raise an exception if
    # database cannot be contacted
    impatient_mongoid_client.collections
    { check_name: 'mongo', ok: true }
  rescue StandardError => e
    { check_name: 'mongo', ok: false, error_details: e.class.to_s }
  ensure
    impatient_mongoid_client.close
  end

  def impatient_mongoid_client
    @impatient_mongoid_client ||= Mongo::Client.new(
      Errbit::Config.mongo_url,
      server_selection_timeout: 0.5,
      connect_timeout:          0.5,
      socket_timeout:           0.5
    )
  end
end
