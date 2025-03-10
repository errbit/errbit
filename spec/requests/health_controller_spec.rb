describe HealthController, type: 'request' do
  let(:errbit_app) { Fabricate(:app, api_key: 'APIKEY') }

  describe "readiness" do
    before do
      if HealthController.instance_variable_defined? :@impatient_mongoid_client
        HealthController.remove_instance_variable :@impatient_mongoid_client
      end
    end

    it 'can let you know when the app is ready to receive requests' do
      get '/health/readiness'
      expect(response).to be_successful
    end

    it 'can indicate if a check fails' do
      expect(Errbit::Config).to receive(:mongo_url) {
        'mongodb://localhost:27000'
      }
      get '/health/readiness'
      expect(response).to be_server_error
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['ok']).to eq false
      expect(parsed_response['details'].first['check_name']).to eq 'mongo'
      expect(parsed_response['details'].first['ok']).to eq false
      expect(parsed_response['details'].first['error_details']).to_not be_nil
    end
  end

  describe "liveness" do
    it 'can let you know that the app is still alive' do
      get '/health/liveness'
      expect(response).to be_successful
    end
  end

  describe "api_key_tester" do
    it 'will let you know when the api_key is not valid' do
      get "/health/api-key-tester?api_key=garbagekey"
      expect(response).to be_forbidden
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['ok']).to eq false
    end

    it 'can let you know that the api_key is valid' do
      get "/health/api-key-tester?api_key=#{errbit_app.api_key}"
      expect(response).to be_successful
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['ok']).to eq true
    end
  end
end
