require 'spec_helper'

describe Api::V1::ProblemsController do

  let(:err) { Fabricate(:err) }
  let(:problem) { err.problem }


  context "when logged in" do
    before do
      @user = Fabricate(:user)
    end

    describe "GET /api/v1/problems" do
      before do
        @app_1 = Fabricate(:app)
        @app_2 = Fabricate(:app)
        Fabricate(:problem_with_err, app: @app_2, first_notice_at: Date.new(2012, 8, 01), resolved_at: Date.new(2012, 8, 02), resolved: true)
        Fabricate(:problem_with_err, app: @app_2, first_notice_at: Date.new(2012, 8, 01), resolved_at: Date.new(2012, 8, 21), resolved: true)
        Fabricate(:problem_with_err, app: @app_1, first_notice_at: Date.new(2012, 8, 21))
        Fabricate(:problem_with_err, app: @app_2, first_notice_at: Date.new(2012, 8, 30))
      end



      it "should return JSON if JSON is requested" do
        get :index, auth_token: @user.authentication_token, format: "json"
        expect { JSON.load(response.body) }.not_to raise_error()#JSON::ParserError)
      end

      it "should return XML if XML is requested" do
        get :index, auth_token: @user.authentication_token, format: "xml"
        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "should return JSON by default" do
        get :index, auth_token: @user.authentication_token
        expect { JSON.load(response.body) }.not_to raise_error()#JSON::ParserError)
      end



      describe "given a date range" do
        it "should return only the problems open during the date range" do
          get :index, {auth_token: @user.authentication_token, start_date: "2012-08-20", end_date: "2012-08-27"}
          expect(response).to be_success
          problems = JSON.load response.body
          expect(problems.length).to eq 2
        end
      end

      describe "given an app" do
        it "should return only the problems for the given app" do
          get :index, {auth_token: @user.authentication_token, app_id: @app_1.id}
          expect(response).to be_success
          problems = JSON.load response.body
          expect(problems.length).to eq 1
        end
      end

      describe "when only open problems are requested" do
        it "should return only the problems haven't been resolved" do
          get :index, {auth_token: @user.authentication_token, open: true}
          expect(response).to be_success
          problems = JSON.load response.body
          expect(problems.length).to eq 2
        end
      end

      it "should return all problems" do
        get :index, {auth_token: @user.authentication_token}
        expect(response).to be_success
        problems = JSON.load response.body
        expect(problems.length).to eq 4
      end



      describe "for each problem" do
        it "should present the url" do
          get :index, {auth_token: @user.authentication_token, app_id: @app_1.id}
          expect(response).to be_success
          problems = JSON.load response.body
          problem = problems.first
          expect(problem["url"]).to eq app_problem_url(@app_1, @app_1.problems.first)
        end

        it "should present all Err ids" do
          Fabricate(:err, problem: @app_1.problems.first)
          get :index, {auth_token: @user.authentication_token, app_id: @app_1.id}
          expect(response).to be_success
          problems = JSON.load response.body
          problem = problems.first
          expect(problem["err_ids"].length).to eq 2
        end
      end
    end



    describe "GET /api/v1/problems/changed" do
      before do
        @before = Time.new(2012, 10, 1, 8, 30)
        @after = Time.new(2012, 10, 1, 11, 30)
        @since = Time.new(2012, 10, 1, 11, 00)
        @app_1 = Fabricate(:app)
        @app_2 = Fabricate(:app)
        Fabricate(:problem_with_err, app: @app_2, deleted_at: @before, updated_at: @before)
        Fabricate(:problem_with_err, app: @app_2, deleted_at: @after, updated_at: @after)
        Fabricate(:problem_with_err, app: @app_1, updated_at: @after)
        Fabricate(:problem_with_err, app: @app_2, updated_at: @after)
      end

      it "should return only problems that have been changed" do
        get :changed, {auth_token: @user.authentication_token, since: @since}
        expect(response).to be_success
        problems = JSON.load response.body
        expect(problems.length).to eq 3
      end

      it "should require 'since' to be supplied" do
        get :changed, {auth_token: @user.authentication_token}
        expect(response.status).to eq 400
      end

      it "should present deleted_at" do
        get :changed, {auth_token: @user.authentication_token, since: @since}
        expect(response).to be_success
        problems = JSON.load response.body
        problem = problems.first
        expect(problem["deleted_at"]).to eq(@after.utc.as_json)
      end
    end



    describe "PUT /api/v1/problems/:id/resolve" do
      it "should resolve the given problem" do
        controller.stub(:problem).and_return(problem)
        expect(problem).to receive(:resolve!)
        put :resolve, id: err.id, auth_token: @user.authentication_token
        expect(response).to be_success
      end

      it "should respond with 404 if the problem doesn't exist" do
        put :resolve, id: 1999, auth_token: @user.authentication_token
        expect(response).to be_not_found
      end

      describe "when supplied a message" do
        it "should create a comment and resolve the problem" do
          controller.stub(:problem).and_return(problem)
          expect(problem).to receive(:resolve!)
          put :resolve, id: err.id, auth_token: @user.authentication_token, message: "Resolved by the Test Suite"
          expect(response).to be_success
          expect(err.comments.pluck(:body)).to eq(["Resolved by the Test Suite"])
        end

        it "should not create a comment if the problem is already resolved" do
          problem.resolve!
          controller.stub(:problem).and_return(problem)
          put :resolve, id: err.id, auth_token: @user.authentication_token, message: "Resolved by the Test Suite"
          expect(response).to be_success
          expect(err.comments.count).to eq(0)
        end
      end
    end



    describe "PUT /api/v1/problems/:id/unresolve" do
      it "should unresolve the given problem" do
        controller.stub(:problem).and_return(problem)
        expect(problem).to receive(:unresolve!)
        put :unresolve, id: err.id, auth_token: @user.authentication_token
        expect(response).to be_success
      end

      it "should respond with 404 if the problem doesn't exist" do
        put :unresolve, id: 1999, auth_token: @user.authentication_token
        expect(response).to be_not_found
      end
    end



    describe "Bulk Actions" do
      before(:each) do
        @problem1 = Fabricate(:err, problem: Fabricate(:problem, resolved: true)).problem
        @problem2 = Fabricate(:err, problem: Fabricate(:problem, resolved: false)).problem
      end

      context "POST api/v1/problems/merge_several" do
        it "should require at least two problems" do
          post :merge_several, problems: [@problem1.id.to_s], auth_token: @user.authentication_token
          expect(response.body).to eql I18n.t('controllers.problems.flash.need_two_errors_merge')
        end

        it "should merge the problems" do
          expect(ProblemMerge).to receive(:new).and_return(double(merge: true))
          post :merge_several, problems: [@problem1.id.to_s, @problem2.id.to_s], auth_token: @user.authentication_token
        end
      end

      context "POST /problems/unmerge_several" do
        it "should require at least one problem" do
          post :unmerge_several, problems: [], auth_token: @user.authentication_token
          expect(response.body).to eql I18n.t('controllers.problems.flash.no_select_problem')
        end

        it "should unmerge a merged problem" do
          merged_problem = Problem.merge!(@problem1, @problem2)
          expect(merged_problem.errs.length).to eq 2
          expect {
            post :unmerge_several, problems: [merged_problem.id.to_s], auth_token: @user.authentication_token
            expect(merged_problem.reload.errs.length).to eq 1
          }.to change(Problem, :count).by(1)
        end
      end

      context "POST /problems/destroy_several" do
        it "should delete the problems" do
          expect {
            post :destroy_several, problems: [@problem1.id.to_s], auth_token: @user.authentication_token
          }.to change(Problem, :count).by(-1)
        end
      end
    end
  end

end
