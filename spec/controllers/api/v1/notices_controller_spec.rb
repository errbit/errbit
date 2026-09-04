# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::NoticesController, type: :controller do
  context "when logged in" do
    before do
      @user = create(:user)
    end

    describe "GET /api/v1/notices" do
      before do
        @first_notice = create(:notice, created_at: Time.zone.parse("2012-08-01"))
        create(:notice, created_at: Time.zone.parse("2012-08-01"))
        create(:notice, created_at: Time.zone.parse("2012-08-21"))
        create(:notice, created_at: Time.zone.parse("2012-08-30"))
      end

      let(:additional_notices) do
        Array.new(101) do |index|
          create(:notice, created_at: Time.zone.parse("2012-08-31") + index.seconds)
        end
      end

      let(:page_notices) do
        Array.new(6) do |index|
          create(:notice, created_at: Time.zone.parse("2012-08-31") + index.seconds)
        end
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

      describe "given an invalid date range" do
        it "should ignore blank and malformed dates" do
          additional_notices

          [
            {start_date: "", end_date: ""},
            {start_date: "invalid", end_date: "2012-08-27"},
            {start_date: ["2012-08-01"], end_date: "2012-08-27"}
          ].each do |date_range|
            get :index, params: {auth_token: @user.authentication_token}.merge(date_range)

            expect(response).to be_successful
            expect(JSON.parse(response.body).length).to eq(100)
          end
        end
      end

      it "should return at most 100 notices by default" do
        additional_notices

        get :index, params: {auth_token: @user.authentication_token}

        expect(response).to be_successful

        notices = JSON.parse(response.body)

        expect(notices.length).to eq(100)
      end

      it "should return the requested number of notices per page" do
        page_notices

        get :index, params: {auth_token: @user.authentication_token, per_page: 10}

        expect(JSON.parse(response.body).length).to eq(10)
      end

      it "should return the requested page" do
        page_notices

        get :index, params: {auth_token: @user.authentication_token, page: 2, per_page: 5}

        notices = JSON.parse(response.body)

        expect(notices.length).to eq(5)
        expect(notices.first["_id"]).to eq(page_notices[1].id.to_s)
      end

      it "uses the default per page value for non-positive values" do
        additional_notices

        [0, -5].each do |per_page|
          get :index, params: {auth_token: @user.authentication_token, per_page: per_page}

          expect(JSON.parse(response.body).length).to eq(100)
        end
      end

      it "uses the default per page value for malformed values" do
        additional_notices

        ["", "invalid", "1.5", [10]].each do |per_page|
          get :index, params: {auth_token: @user.authentication_token, per_page: per_page}

          expect(JSON.parse(response.body).length).to eq(100)
        end
      end

      it "caps per page at 100" do
        additional_notices

        get :index, params: {auth_token: @user.authentication_token, per_page: 500}

        expect(JSON.parse(response.body).length).to eq(100)
      end

      it "uses the first page for malformed page values" do
        [0, -5, "", "invalid", "1.5", [2]].each do |page|
          get :index, params: {auth_token: @user.authentication_token, page: page, per_page: 5}

          notices = JSON.parse(response.body)

          expect(notices.first["_id"]).to eq(@first_notice.id.to_s)
        end
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
