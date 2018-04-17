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

private

  def run_mongo_check
    Timeout.timeout(0.75) do
      # collections might be empty which is ok but it will raise an exception if
      # database cannot be contacted
      Mongoid.default_client.collections
    end
    { check_name: 'mongo', ok: true }
  rescue StandardError => e
    { check_name: 'mongo', ok: false, error_details: "#{e.class}: #{e.message}" }
  end
end
