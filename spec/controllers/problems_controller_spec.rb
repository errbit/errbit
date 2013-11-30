require 'spec_helper'

describe ProblemsController do

  it_requires_authentication :for => {
    :index => :get, :show => :get, :resolve => :put, :search => :get
  },
  :params => {:app_id => 'dummyid', :id => 'dummyid'}

  let(:app) { Fabricate(:app) }
  let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :environment => "production")) }


  describe "GET /problems" do
    #render_views
    context 'when logged in as an admin' do
      before(:each) do
        @user = Fabricate(:admin)
        sign_in @user
        @problem = Fabricate(:notice, :err => Fabricate(:err, :problem => Fabricate(:problem, :app => app, :environment => "production"))).problem
      end

      context "pagination" do
        before(:each) do
          35.times { Fabricate :err }
        end

        it "should have default per_page value for user" do
          get :index
          expect(controller.problems.to_a.size).to eq User::PER_PAGE
        end

        it "should be able to override default per_page value" do
          @user.update_attribute :per_page, 10
          get :index
          expect(controller.problems.to_a.size).to eq 10
        end
      end

      context 'with environment filters' do
        before(:each) do
          environments = ['production', 'test', 'development', 'staging']
          20.times do |i|
            Fabricate(:problem, :environment => environments[i % environments.length])
          end
        end

        context 'no params' do
          it 'shows problems for all environments' do
            get :index
            expect(controller.problems.size).to eq 21
          end
        end

        context 'environment production' do
          it 'shows problems for just production' do
            get :index, :environment => 'production'
            expect(controller.problems.size).to eq 6
          end
        end

        context 'environment staging' do
          it 'shows problems for just staging' do
            get :index, :environment => 'staging'
            expect(controller.problems.size).to eq 5
          end
        end

        context 'environment development' do
          it 'shows problems for just development' do
            get :index, :environment => 'development'
            expect(controller.problems.size).to eq 5
          end
        end

        context 'environment test' do
          it 'shows problems for just test' do
            get :index, :environment => 'test'
            expect(controller.problems.size).to eq 5
          end
        end
      end
    end

    context 'when logged in as a user' do
      it 'gets a paginated list of unresolved problems for the users apps' do
        sign_in(user = Fabricate(:user))
        unwatched_err = Fabricate(:err)
        watched_unresolved_err = Fabricate(:err, :problem => Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => false))
        watched_resolved_err = Fabricate(:err, :problem => Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => true))
        get :index
        expect(controller.problems).to include(watched_unresolved_err.problem)
        expect(controller.problems).to_not include(unwatched_err.problem, watched_resolved_err.problem)
      end
    end
  end

  describe "GET /problems - previously all" do
    context 'when logged in as an admin' do
      it "gets a paginated list of all problems" do
        sign_in Fabricate(:admin)
        problems = Kaminari.paginate_array((1..30).to_a)
        3.times { problems << Fabricate(:err).problem }
        3.times { problems << Fabricate(:err, :problem => Fabricate(:problem, :resolved => true)).problem }
        expect(Problem).to receive(:ordered_by).and_return(
          double('proxy', :page => double('other_proxy', :per => problems))
        )
        get :index, :all_errs => true
        expect(controller.problems).to eq problems
      end
    end

    context 'when logged in as a user' do
      it 'gets a paginated list of all problems for the users apps' do
        sign_in(user = Fabricate(:user))
        unwatched_problem = Fabricate(:problem)
        watched_unresolved_problem = Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => false)
        watched_resolved_problem = Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => true)
        get :index, :all_errs => true
        expect(controller.problems).to include(watched_resolved_problem, watched_unresolved_problem)
        expect(controller.problems).to_not include(unwatched_problem)
      end
    end
  end

  describe "GET /apps/:app_id/problems/:id" do
    #render_views

    context 'when logged in as an admin' do
      before do
        sign_in Fabricate(:admin)
      end

      it "finds the app" do
        get :show, :app_id => app.id, :id => err.problem.id
        expect(controller.app).to eq app
      end

      it "finds the problem" do
        get :show, :app_id => app.id, :id => err.problem.id
        expect(controller.problem).to eq err.problem
      end

      it "successfully render page" do
        get :show, :app_id => app.id, :id => err.problem.id
        expect(response).to be_success
      end

      context 'pagination' do
        let!(:notices) do
          3.times.reduce([]) do |coll, i|
            coll << Fabricate(:notice, :err => err, :created_at => (Time.now + i))
          end
        end

        it "paginates the notices 1 at a time, starting with the most recent" do
          get :show, :app_id => app.id, :id => err.problem.id
          expect(assigns(:notices).entries.count).to eq 1
          expect(assigns(:notices)).to include(notices.last)
        end

        it "paginates the notices 1 at a time, based on then notice param" do
          get :show, :app_id => app.id, :id => err.problem.id, :notice => 3
          expect(assigns(:notices).entries.count).to eq 1
          expect(assigns(:notices)).to include(notices.first)
        end
      end

    end

    context 'when logged in as a user' do
      before do
        sign_in(@user = Fabricate(:user))
        @unwatched_err = Fabricate(:err)
        @watched_app = Fabricate(:app)
        @watcher = Fabricate(:user_watcher, :user => @user, :app => @watched_app)
        @watched_err = Fabricate(:err, :problem => Fabricate(:problem, :app => @watched_app))
      end

      it 'finds the problem if the user is watching the app' do
        get :show, :app_id => @watched_app.to_param, :id => @watched_err.problem.id
        expect(controller.problem).to eq @watched_err.problem
      end

      it 'raises a DocumentNotFound error if the user is not watching the app' do
        expect {
          get :show, :app_id => @unwatched_err.problem.app_id, :id => @unwatched_err.problem.id
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "PUT /apps/:app_id/problems/:id/resolve" do
    before do
      sign_in Fabricate(:admin)

      @problem = Fabricate(:err)
      App.stub(:find).with(@problem.app.id.to_s).and_return(@problem.app)
      @problem.app.problems.stub(:find).and_return(@problem.problem)
      @problem.problem.stub(:resolve!)
    end

    it 'finds the app and the problem' do
      expect(App).to receive(:find).with(@problem.app.id.to_s).and_return(@problem.app)
      expect(@problem.app.problems).to receive(:find).and_return(@problem.problem)
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      expect(controller.app).to eq @problem.app
      expect(controller.problem).to eq @problem.problem
    end

    it "should resolve the issue" do
      expect(@problem.problem).to receive(:resolve!).and_return(true)
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
    end

    it "should display a message" do
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      expect(request.flash[:success]).to match(/Great news/)
    end

    it "should redirect to the app page" do
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      expect(response).to redirect_to(app_path(@problem.app))
    end

    it "should redirect back to problems page" do
      request.env["Referer"] = problems_path
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      expect(response).to redirect_to(problems_path)
    end
  end

  describe "POST /apps/:app_id/problems/:id/create_issue" do
    #render_views

    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "successful issue creation" do
      context "lighthouseapp tracker" do
        let(:notice) { Fabricate :notice }
        let(:tracker) { Fabricate :lighthouse_tracker, :app => notice.app }
        let(:problem) { notice.problem }

        before(:each) do
          number = 5
          @issue_link = "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets/#{number}.xml"
          body = "<ticket><number type=\"integer\">#{number}</number></ticket>"
          stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").
                       to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

          post :create_issue, :app_id => problem.app.id, :id => problem.id
          problem.reload
        end

        it "should redirect to problem page" do
          expect(response).to redirect_to( app_problem_path(problem.app, problem) )
        end
      end
    end

    context "absent issue tracker" do
      let(:problem) { Fabricate :problem }

      before(:each) do
        post :create_issue, :app_id => problem.app.id, :id => problem.id
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to( app_problem_path(problem.app, problem) )
      end

      it "should set flash error message telling issue tracker of the app doesn't exist" do
        expect(flash[:error]).to eq "This app has no issue tracker setup."
      end
    end

    context "error during request to a tracker" do
      context "lighthouseapp tracker" do
        let(:tracker) { Fabricate :lighthouse_tracker }
        let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => tracker.app)) }

        before(:each) do
          stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").to_return(:status => 500)

          post :create_issue, :app_id => err.app.id, :id => err.problem.id
        end

        it "should redirect to problem page" do
          expect(response).to redirect_to( app_problem_path(err.app, err.problem) )
        end

        it "should notify of connection error" do
          expect(flash[:error]).to include("There was an error during issue creation:")
        end
      end
    end
  end

  describe "DELETE /apps/:app_id/problems/:id/unlink_issue" do
    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "problem with issue" do
      let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :issue_link => "http://some.host")) }

      before(:each) do
        delete :unlink_issue, :app_id => err.app.id, :id => err.problem.id
        err.problem.reload
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to( app_problem_path(err.app, err.problem) )
      end

      it "should clear issue link" do
        expect(err.problem.issue_link).to be_nil
      end
    end

    context "err without issue" do
      let(:err) { Fabricate :err }

      before(:each) do
        delete :unlink_issue, :app_id => err.app.id, :id => err.problem.id
        err.problem.reload
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to( app_problem_path(err.app, err.problem) )
      end
    end
  end

  describe "Bulk Actions" do
    before(:each) do
      sign_in Fabricate(:admin)
      @problem1 = Fabricate(:err, :problem => Fabricate(:problem, :resolved => true)).problem
      @problem2 = Fabricate(:err, :problem => Fabricate(:problem, :resolved => false)).problem
    end

    context "POST /problems/merge_several" do
      it "should require at least two problems" do
        post :merge_several, :problems => [@problem1.id.to_s]
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.need_two_errors_merge')
      end

      it "should merge the problems" do
        expect(ProblemMerge).to receive(:new).and_return(double(:merge => true))
        post :merge_several, :problems => [@problem1.id.to_s, @problem2.id.to_s]
      end
    end

    context "POST /problems/unmerge_several" do

      it "should require at least one problem" do
        post :unmerge_several, :problems => []
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.no_select_problem')
      end

      it "should unmerge a merged problem" do
        merged_problem = Problem.merge!(@problem1, @problem2)
        expect(merged_problem.errs.length).to eq 2
        expect{
          post :unmerge_several, :problems => [merged_problem.id.to_s]
          expect(merged_problem.reload.errs.length).to eq 1
        }.to change(Problem, :count).by(1)
      end

    end

    context "POST /problems/resolve_several" do

      it "should require at least one problem" do
        post :resolve_several, :problems => []
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.no_select_problem')
      end

      it "should resolve the issue" do
        post :resolve_several, :problems => [@problem2.id.to_s]
        expect(@problem2.reload.resolved?).to eq true
      end

      it "should display a message about 1 err" do
        post :resolve_several, :problems => [@problem2.id.to_s]
        expect(flash[:success]).to match(/1 err has been resolved/)
      end

      it "should display a message about 2 errs" do
        post :resolve_several, :problems => [@problem1.id.to_s, @problem2.id.to_s]
        expect(flash[:success]).to match(/2 errs have been resolved/)
        expect(controller.selected_problems).to eq [@problem1, @problem2]
      end
    end

    context "POST /problems/unresolve_several" do

      it "should require at least one problem" do
        post :unresolve_several, :problems => []
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.no_select_problem')
      end

      it "should unresolve the issue" do
        post :unresolve_several, :problems => [@problem1.id.to_s]
        expect(@problem1.reload.resolved?).to eq false
      end
    end

    context "POST /problems/destroy_several" do
      it "should delete the problems" do
        expect{
          post :destroy_several, :problems => [@problem1.id.to_s]
        }.to change(Problem, :count).by(-1)
      end
    end
  end

end

