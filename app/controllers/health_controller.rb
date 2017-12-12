class HealthController < ActionController::Base
  def readiness
    check_results = [run_mongo_check]
    all_ok = check_results.all? do |check|
      check[:ok]
    end
    render json: { ok: all_ok, details: check_results }, status: :ok
  end

  def liveness
    render json: { ok: true }, status: :ok
  end

private

  def run_mongo_check
    Timeout.timeout(3) do
      Mongoid.default_client.database_names.present?
    end
    { check_name: 'mongo', ok: true }
  rescue StandardError => e
    { check_name: 'mongo', ok: false, error_details: "#{e.class}: #{e.message}" }
  end
end
