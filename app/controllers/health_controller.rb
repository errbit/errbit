class HealthController < ActionController::Base
  class << self
    def impatient_mongoid_client
      @impatient_mongoid_client ||= Mongo::Client.new(
        Errbit::Config.mongo_url,
        server_selection_timeout: 0.5,
        connect_timeout:          0.5,
        socket_timeout:           0.5
      )
    end

    def clear_mongoid_client_cache
      @impatient_mongoid_client = nil
    end
  end

  def readiness
    check_results = [run_mongo_check]
    all_ok = check_results.all? do |check|
      check[:ok]
    end
    response_status = all_ok ? :ok : :internal_server_error
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

  delegate :impatient_mongoid_client, :clear_mongoid_client_cache, to: :class

  def run_mongo_check
    # remember this client in a local variable so we can clear the cached
    # client if it fails, but still always close the connection
    local_mongoid_client = impatient_mongoid_client

    # collections might be empty which is ok but it will raise an exception if
    # database cannot be contacted
    local_mongoid_client.collections
    { check_name: "mongo", ok: true }
  rescue StandardError => e
    clear_mongoid_client_cache
    { check_name: "mongo", ok: false, error_details: e.class.to_s }
  ensure
    local_mongoid_client.close
  end
end
