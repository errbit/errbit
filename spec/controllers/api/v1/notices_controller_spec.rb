# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::NoticesController, type: :controller do
  context "when logged in" do
    before do
      @user = Fabricate(:user)
    end

    describe "GET /api/v1/notices" do
      before do
        Fabricate(:notice, created_at: Time.zone.parse("2012-08-01"))
        Fabricate(:notice, created_at: Time.zone.parse("2012-08-01"))
        Fabricate(:notice, created_at: Time.zone.parse("2012-08-21"))
        Fabricate(:notice, created_at: Time.zone.parse("2012-08-30"))
      end

      it "should return JSON if JSON is requested" do
        get :index, params: {auth_token: @user.authentication_token, format: "json"}

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "should return XML if XML is requested" do
        get :index, params: {auth_token: @user.authentication_token, format: "xml"}

        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "should return JSON by default" do
        get :index, params: {auth_token: @user.authentication_token}

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      describe "given a date range" do
        it "should return only the notices created during the date range" do
          get :index, params: {auth_token: @user.authentication_token, start_date: "2012-08-01", end_date: "2012-08-27"}

          expect(response).to be_successful

          notices = JSON.parse(response.body)

          expect(notices.length).to eq(3)
        end
      end

      it "should return all notices" do
        get :index, params: {auth_token: @user.authentication_token}

        expect(response).to be_successful

        notices = JSON.parse(response.body)

        expect(notices.length).to eq(4)
      end

      it "should return notice objects with correct fields" do
        get :index, params: {auth_token: @user.authentication_token, format: "json"}

        notices = JSON.parse(response.body)
        notice = notices.first

        expect(notice).to be_a(Hash)
        expect(notice.keys).to match_array(["_id", "created_at", "message", "error_class"])
      end
    end
  end
end
