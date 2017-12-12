describe "Health", type: 'request' do
  describe "readiness" do
    it 'can let you know when the app is ready to receive requests' do
      get '/health/readiness'
      expect(response).to be_success
    end

    it 'can indicate if a check fails' do
      expect(Mongoid.default_client).to receive(:database_names).and_raise(Mongo::Error::NoServerAvailable)
      get '/health/readiness'
      expect(response).to be_success
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
end
