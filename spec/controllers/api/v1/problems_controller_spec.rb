# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ProblemsController, type: :controller do
  context "when logged in" do
    let(:user) { create(:errbit_user) }

    describe "GET /api/v1/problems/:id" do
      let!(:problem) { create(:errbit_problem) }

      it "returns JSON when JSON is requested" do
        get :show, params: {auth_token: user.authentication_token, format: "json", id: problem.id}

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns XML when XML is requested" do
        get :show, params: {auth_token: user.authentication_token, format: "xml", id: problem.id}

        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "returns JSON by default" do
        get :show, params: {auth_token: user.authentication_token, id: problem.id}

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns the correct problem" do
        get :show, params: {auth_token: user.authentication_token, format: "json", id: problem.id}

        expect(JSON.parse(response.body)["_id"]).to eq(problem.id.to_s)
      end

      it "returns only the legacy v1 keys" do
        get :show, params: {auth_token: user.authentication_token, format: "json", id: problem.id}

        expect(JSON.parse(response.body).keys).to match_array([
          "app_name", "first_notice_at", "message", "app_id", "last_notice_at",
          "_id", "resolved", "resolved_at", "where", "notices_count", "environment"
        ])
      end

      it "returns 404 when the problem cannot be found" do
        get :show, params: {auth_token: user.authentication_token, format: "json", id: "999999999"}

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /api/v1/problems" do
      before do
        create(:errbit_problem, first_notice_at: Date.new(2012, 8, 1), resolved_at: Date.new(2012, 8, 2))
        create(:errbit_problem, first_notice_at: Date.new(2012, 8, 1), resolved_at: Date.new(2012, 8, 21))
        create(:errbit_problem, first_notice_at: Date.new(2012, 8, 21))
        create(:errbit_problem, first_notice_at: Date.new(2012, 8, 30))
      end

      it "returns JSON when JSON is requested" do
        get :index, params: {auth_token: user.authentication_token, format: "json"}

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns XML when XML is requested" do
        get :index, params: {auth_token: user.authentication_token, format: "xml"}

        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "returns JSON by default" do
        get :index, params: {auth_token: user.authentication_token}

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      context "with a date range" do
        it "returns only the problems open during the date range" do
          get :index, params: {auth_token: user.authentication_token, start_date: "2012-08-20", end_date: "2012-08-27"}

          expect(response).to be_successful

          expect(JSON.parse(response.body).length).to eq(2)
        end
      end

      it "returns every problem when no date range is given" do
        get :index, params: {auth_token: user.authentication_token}

        expect(response).to be_successful

        expect(JSON.parse(response.body).length).to eq(4)
      end

      it "returns problem objects with the legacy v1 keys" do
        get :index, params: {auth_token: user.authentication_token, format: "json"}

        problem = JSON.parse(response.body).first

        expect(problem).to be_a(Hash)
        expect(problem.keys).to match_array([
          "_id", "app_id", "app_name", "environment", "message", "where",
          "first_notice_at", "last_notice_at", "resolved", "resolved_at",
          "notices_count"
        ])
      end
    end
  end
end
