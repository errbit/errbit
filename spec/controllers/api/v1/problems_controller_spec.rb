require 'spec_helper'

describe Api::V1::ProblemsController do

  context "when logged in" do
    before do
      @user = Fabricate(:user)
    end

    describe "GET /api/v1/problems/:id" do
      before do
        notice = Fabricate(:notice)
        err = Fabricate(:err, :notices => [notice])
        @problem = Fabricate(:problem, :errs => [err])
      end

      it "should return JSON if JSON is requested" do
        get :show, :auth_token => @user.authentication_token, :format => "json", :id => Problem.first.id
        expect { JSON.load(response.body) }.not_to raise_error() #JSON::ParserError
      end

      it "should return XML if XML is requested" do
        get :index, :auth_token => @user.authentication_token, :format => "xml", :id => @problem.id
        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "should return JSON by default" do
        get :show, :auth_token => @user.authentication_token, :id => @problem.id
        expect { JSON.load(response.body) }.not_to raise_error()#JSON::ParserError)
      end

      it "should return the correct problem" do
        get :show, :auth_token => @user.authentication_token, :format => "json", :id => @problem.id

        returned_problem = JSON.parse(response.body)
        expect( returned_problem["_id"] ).to eq(@problem.id.to_s)
      end

      it "should return only the correct fields" do
        get :show, :auth_token => @user.authentication_token, :format => "json", :id => @problem.id
        returned_problem = JSON.parse(response.body)

        expect( returned_problem.keys ).to match_array([
          "app_name",
          "first_notice_at",
          "error_class",
          "messages",
          "hosts",
          "created_at",
          "app_id",
          "last_notice_at",
          "_id",
          "issue_link",
          "resolved",
          "updated_at",
          "resolved_at",
          "last_deploy_at",
          "where",
          "issue_type",
          "notices_count",
          "user_agents",
          "comments_count",
          "message",
          "environment"
        ])
      end

      it "returns a 404 if the problem cannot be found" do
        get :show, :auth_token => @user.authentication_token, :format => "json", :id => 'IdontExist'
        expect( response.status ).to eq(404)
      end
    end

    describe "GET /api/v1/problems" do
      before do
        Fabricate(:problem, :first_notice_at => Date.new(2012, 8, 01), :resolved_at => Date.new(2012, 8, 02))
        Fabricate(:problem, :first_notice_at => Date.new(2012, 8, 01), :resolved_at => Date.new(2012, 8, 21))
        Fabricate(:problem, :first_notice_at => Date.new(2012, 8, 21))
        Fabricate(:problem, :first_notice_at => Date.new(2012, 8, 30))
      end



      it "should return JSON if JSON is requested" do
        get :index, :auth_token => @user.authentication_token, :format => "json"
        expect { JSON.load(response.body) }.not_to raise_error()#JSON::ParserError)
      end

      it "should return XML if XML is requested" do
        get :index, :auth_token => @user.authentication_token, :format => "xml"
        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "should return JSON by default" do
        get :index, :auth_token => @user.authentication_token
        expect { JSON.load(response.body) }.not_to raise_error()#JSON::ParserError)
      end



      describe "given a date range" do

        it "should return only the problems open during the date range" do
          get :index, {:auth_token => @user.authentication_token, :start_date => "2012-08-20", :end_date => "2012-08-27"}
          expect(response).to be_success
          problems = JSON.load response.body
          expect(problems.length).to eq 2
        end

      end

      it "should return all problems" do
        get :index, {:auth_token => @user.authentication_token}
        expect(response).to be_success
        problems = JSON.load response.body
        expect(problems.length).to eq 4
      end

    end
  end

end
