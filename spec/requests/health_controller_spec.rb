# frozen_string_literal: true

require "rails_helper"

RSpec.describe HealthController, type: :request do
  let(:errbit_app) { create(:app, api_key: "APIKEY") }

  describe "api_key_tester" do
    it "will let you know when the api_key is not valid" do
      get "/health/api-key-tester?api_key=garbagekey"

      expect(response).to be_forbidden

      expect(response.parsed_body["ok"]).to eq(false)
    end

    it "can let you know that the api_key is valid" do
      get "/health/api-key-tester?api_key=#{errbit_app.api_key}"

      expect(response).to be_successful

      expect(response.parsed_body["ok"]).to eq(true)
    end
  end
end
