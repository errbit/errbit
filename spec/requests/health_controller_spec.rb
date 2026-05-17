# frozen_string_literal: true

require "rails_helper"

RSpec.describe HealthController, type: :request do
  let(:errbit_app) { create(:errbit_app, api_key: "APIKEY") }

  describe "api_key_tester" do
    context "with an unknown api_key" do
      it "returns 403 with ok=false" do
        get "/health/api-key-tester?api_key=garbagekey"

        expect(response).to be_forbidden
        expect(response.parsed_body["ok"]).to eq(false)
      end
    end

    context "with a valid api_key" do
      it "returns 200 with ok=true" do
        get "/health/api-key-tester?api_key=#{errbit_app.api_key}"

        expect(response).to be_successful
        expect(response.parsed_body["ok"]).to eq(true)
      end
    end
  end
end
