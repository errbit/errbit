describe "Health", type: 'request' do
  let(:errbit_app) { Fabricate(:app, api_key: 'APIKEY') }

  describe "readiness" do
    it 'can let you know when the app is ready to receive requests' do
      get '/health/readiness'
      expect(response).to be_success
    end

    it 'can indicate if a check fails' do
      expect(Mongoid.default_client).to receive(:collections).and_raise(Mongo::Error::NoServerAvailable)
      get '/health/readiness'
      expect(response).to be_error
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
      expect(response).to be_success
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
      expect(response).to be_success
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['ok']).to eq true
    end
  end
end
