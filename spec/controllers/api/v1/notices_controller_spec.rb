require 'spec_helper'

describe Api::V1::NoticesController do

  context "when logged in" do
    before do
      @user = Fabricate(:user)
    end

    describe "GET /api/v1/notices" do
      before do
        Fabricate(:notice, :created_at => DateTime.new(2012, 8, 01))
        Fabricate(:notice, :created_at => DateTime.new(2012, 8, 01))
        Fabricate(:notice, :created_at => DateTime.new(2012, 8, 21))
        Fabricate(:notice, :created_at => DateTime.new(2012, 8, 30))
      end

      it "should return JSON if JSON is requested" do
        get :index, :auth_token => @user.authentication_token, :format => "json"
        lambda { JSON.load(response.body) }.should_not raise_error(JSON::ParserError)
      end

      it "should return XML if XML is requested" do
        get :index, :auth_token => @user.authentication_token, :format => "xml"
        Nokogiri::XML(response.body).errors.should be_empty
      end

      it "should return JSON by default" do
        get :index, :auth_token => @user.authentication_token
        lambda { JSON.load(response.body) }.should_not raise_error(JSON::ParserError)
      end

      describe "given a date range" do

        it "should return only the notices created during the date range" do
          get :index, {:auth_token => @user.authentication_token, :start_date => "2012-08-01", :end_date => "2012-08-27"}
          response.should be_success
          notices = JSON.load response.body
          notices.length.should == 3
        end

      end

      it "should return all notices" do
        get :index, {:auth_token => @user.authentication_token}
        response.should be_success
        notices = JSON.load response.body
        notices.length.should == 4
      end

    end
  end

end
