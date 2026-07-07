# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::NoticesController, type: :controller do
  context "when logged in" do
    let(:user) { create(:errbit_user) }

    describe "GET /api/v1/notices" do
      before do
        create(:errbit_notice, created_at: Time.zone.parse("2012-08-01"))
        create(:errbit_notice, created_at: Time.zone.parse("2012-08-01"))
        create(:errbit_notice, created_at: Time.zone.parse("2012-08-21"))
        create(:errbit_notice, created_at: Time.zone.parse("2012-08-30"))
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
        it "returns only the notices created during the date range" do
          get :index, params: {auth_token: user.authentication_token, start_date: "2012-08-01", end_date: "2012-08-27"}

          expect(response).to be_successful

          expect(JSON.parse(response.body).length).to eq(3)
        end
      end

      it "returns every notice when no date range is given" do
        get :index, params: {auth_token: user.authentication_token}

        expect(response).to be_successful

        expect(JSON.parse(response.body).length).to eq(4)
      end

      it "returns notice objects with the legacy v1 keys" do
        get :index, params: {auth_token: user.authentication_token, format: "json"}

        notice = JSON.parse(response.body).first

        expect(notice).to be_a(Hash)
        expect(notice.keys).to match_array(["_id", "created_at", "message", "error_class"])
      end
    end
  end
end
