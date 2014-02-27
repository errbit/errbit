require 'spec_helper'

describe Api::V1::ProblemsController do
  
  
  let(:problem) do
    Fabricate(:problem)
  end
  
  
  context "when logged in" do
    before do
      @user = Fabricate(:user)
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


    describe "PUT /api/v1/problems/:id/resolve" do
      it "should resolve the given problem" do
        controller.stub(:problem).and_return(problem)
        expect(problem).to receive(:resolve!)
        put :resolve, :id => problem.id, :auth_token => @user.authentication_token, :format => "json"
        expect(response).to be_success
      end
      
      it "should respond with 404 if the problem doesn't exist" do
        put :resolve, :id => 1999, :auth_token => @user.authentication_token, :format => "json"
        expect(response).to be_not_found
      end
    end


    describe "PUT /api/v1/problems/:id/unresolve" do
      it "should unresolve the given problem" do
        controller.stub(:problem).and_return(problem)
        expect(problem).to receive(:unresolve!)
        put :unresolve, :id => problem.id, :auth_token => @user.authentication_token, :format => "json"
        expect(response).to be_success
      end
      
      it "should respond with 404 if the problem doesn't exist" do
        put :unresolve, :id => 1999, :auth_token => @user.authentication_token, :format => "json"
        expect(response).to be_not_found
      end
    end
  end

end
