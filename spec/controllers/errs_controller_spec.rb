require 'spec_helper'

describe ErrsController do

  it_requires_authentication :for => {
    :index => :get, :all => :get, :show => :get, :resolve => :put
  },
  :params => {:app_id => 'dummyid', :id => 'dummyid'}

  let(:app) { Fabricate(:app) }
  let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :environment => "production")) }


  describe "GET /errs" do
    render_views
    context 'when logged in as an admin' do
      before(:each) do
        @user = Fabricate(:admin)
        sign_in @user
        @problem = Fabricate(:notice, :err => Fabricate(:err, :problem => Fabricate(:problem, :app => app, :environment => "production"))).problem
      end

      it "should successfully list errs" do
        get :index
        response.should be_success
        response.body.gsub("&#8203;", "").should match(@problem.message)
      end

      it "should list atom feed successfully" do
        get :index, :format => "atom"
        response.should be_success
        response.body.should match(@problem.message)
      end

      context "pagination" do
        before(:each) do
          35.times { Fabricate :err }
        end

        it "should have default per_page value for user" do
          get :index
          assigns(:problems).to_a.size.should == User::PER_PAGE
        end

        it "should be able to override default per_page value" do
          @user.update_attribute :per_page, 10
          get :index
          assigns(:problems).to_a.size.should == 10
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
          it 'shows errs for all environments' do
            get :index
            assigns(:problems).size.should == 21
          end
        end

        context 'environment production' do
          it 'shows errs for just production' do
            get :index, :environment => 'production'
            assigns(:problems).size.should == 6
          end
        end

        context 'environment staging' do
          it 'shows errs for just staging' do
            get :index, :environment => 'staging'
            assigns(:problems).size.should == 5
          end
        end

        context 'environment development' do
          it 'shows errs for just development' do
            get :index, :environment => 'development'
            assigns(:problems).size.should == 5
          end
        end

        context 'environment test' do
          it 'shows errs for just test' do
            get :index, :environment => 'test'
            assigns(:problems).size.should == 5
          end
        end
      end
    end

    context 'when logged in as a user' do
      it 'gets a paginated list of unresolved errs for the users apps' do
        sign_in(user = Fabricate(:user))
        unwatched_err = Fabricate(:err)
        watched_unresolved_err = Fabricate(:err, :problem => Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => false))
        watched_resolved_err = Fabricate(:err, :problem => Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => true))
        get :index
        assigns(:problems).should include(watched_unresolved_err.problem)
        assigns(:problems).should_not include(unwatched_err.problem, watched_resolved_err.problem)
      end
    end
  end

  describe "GET /errs/all" do
    context 'when logged in as an admin' do
      it "gets a paginated list of all errs" do
        sign_in Fabricate(:admin)
        errs = Kaminari.paginate_array((1..30).to_a)
        3.times { errs << Fabricate(:err).problem }
        3.times { errs << Fabricate(:err, :problem => Fabricate(:problem, :resolved => true)).problem }
        Problem.should_receive(:ordered).and_return(
          mock('proxy', :page => mock('other_proxy', :per => errs))
        )
        get :all
        assigns(:problems).should == errs
      end
    end

    context 'when logged in as a user' do
      it 'gets a paginated list of all errs for the users apps' do
        sign_in(user = Fabricate(:user))
        unwatched_err = Fabricate(:problem)
        watched_unresolved_err = Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => false)
        watched_resolved_err = Fabricate(:problem, :app => Fabricate(:user_watcher, :user => user).app, :resolved => true)
        get :all
        assigns(:problems).should include(watched_resolved_err, watched_unresolved_err)
        assigns(:problems).should_not include(unwatched_err)
      end
    end
  end

  describe "GET /apps/:app_id/errs/:id" do
    render_views

    before do
      3.times { Fabricate(:notice, :err => err)}
    end

    context 'when logged in as an admin' do
      before do
        sign_in Fabricate(:admin)
      end

      it "finds the app" do
        get :show, :app_id => app.id, :id => err.problem.id
        assigns(:app).should == app
      end

      it "finds the err" do
        get :show, :app_id => app.id, :id => err.problem.id
        assigns(:problem).should == err.problem
      end

      it "successfully render page" do
        get :show, :app_id => app.id, :id => err.problem.id
        response.should be_success
      end

      context "create issue button" do
        let(:button_matcher) { match(/create issue/) }

        it "should not exist for err's app without issue tracker" do
          err = Fabricate :err
          get :show, :app_id => err.app.id, :id => err.problem.id

          response.body.should_not button_matcher
        end

        it "should exist for err's app with issue tracker" do
          tracker = Fabricate(:lighthouse_tracker)
          err = Fabricate(:err, :problem => Fabricate(:problem, :app => tracker.app))
          get :show, :app_id => err.app.id, :id => err.problem.id

          response.body.should button_matcher
        end

        it "should not exist for err with issue_link" do
          tracker = Fabricate(:lighthouse_tracker)
          err = Fabricate(:err, :problem => Fabricate(:problem, :app => tracker.app, :issue_link => "http://some.host"))
          get :show, :app_id => err.app.id, :id => err.problem.id

          response.body.should_not button_matcher
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

      it 'finds the err if the user is watching the app' do
        get :show, :app_id => @watched_app.to_param, :id => @watched_err.problem.id
        assigns(:problem).should == @watched_err.problem
      end

      it 'raises a DocumentNotFound error if the user is not watching the app' do
        lambda {
          get :show, :app_id => @unwatched_err.problem.app_id, :id => @unwatched_err.problem.id
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "PUT /apps/:app_id/errs/:id/resolve" do
    before do
      sign_in Fabricate(:admin)

      @problem = Fabricate(:err)
      App.stub(:find).with(@problem.app.id).and_return(@problem.app)
      @problem.app.problems.stub(:find).and_return(@problem.problem)
      @problem.problem.stub(:resolve!)
    end

    it 'finds the app and the err' do
      App.should_receive(:find).with(@problem.app.id).and_return(@problem.app)
      @problem.app.problems.should_receive(:find).and_return(@problem.problem)
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      assigns(:app).should == @problem.app
      assigns(:problem).should == @problem.problem
    end

    it "should resolve the issue" do
      @problem.problem.should_receive(:resolve!).and_return(true)
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
    end

    it "should display a message" do
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      request.flash[:success].should match(/Great news/)
    end

    it "should redirect to the app page" do
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      response.should redirect_to(app_path(@problem.app))
    end

    it "should redirect back to errs page" do
      request.env["Referer"] = errs_path
      put :resolve, :app_id => @problem.app.id, :id => @problem.problem.id
      response.should redirect_to(errs_path)
    end
  end

  describe "POST /apps/:app_id/errs/:id/create_issue" do
    render_views

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
          response.should redirect_to( app_err_path(problem.app, problem) )
        end
      end
    end

    context "absent issue tracker" do
      let(:problem) { Fabricate :problem }

      before(:each) do
        post :create_issue, :app_id => problem.app.id, :id => problem.id
      end

      it "should redirect to problem page" do
        response.should redirect_to( app_err_path(problem.app, problem) )
      end

      it "should set flash error message telling issue tracker of the app doesn't exist" do
        flash[:error].should == "This app has no issue tracker setup."
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

        it "should redirect to err page" do
          response.should redirect_to( app_err_path(err.app, err.problem) )
        end

        it "should notify of connection error" do
          flash[:error].should == "There was an error during issue creation. Check your tracker settings or try again later."
        end
      end
    end
  end

  describe "DELETE /apps/:app_id/errs/:id/unlink_issue" do
    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "err with issue" do
      let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :issue_link => "http://some.host")) }

      before(:each) do
        delete :unlink_issue, :app_id => err.app.id, :id => err.problem.id
        err.problem.reload
      end

      it "should redirect to err page" do
        response.should redirect_to( app_err_path(err.app, err.problem) )
      end

      it "should clear issue link" do
        err.problem.issue_link.should be_nil
      end
    end

    context "err without issue" do
      let(:err) { Fabricate :err }

      before(:each) do
        delete :unlink_issue, :app_id => err.app.id, :id => err.problem.id
        err.problem.reload
      end

      it "should redirect to err page" do
        response.should redirect_to( app_err_path(err.app, err.problem) )
      end
    end
  end


  describe "POST /apps/:app_id/errs/:id/create_comment" do
    render_views

    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "successful comment creation" do
      let(:problem) { Fabricate(:problem) }
      let(:user) { Fabricate(:user) }

      before(:each) do
        post :create_comment, :app_id => problem.app.id, :id => problem.id,
             :comment => { :body => "One test comment", :user_id => user.id }
        problem.reload
      end

      it "should create the comment" do
        problem.comments.size.should == 1
      end

      it "should redirect to problem page" do
        response.should redirect_to( app_err_path(problem.app, problem) )
      end
    end
  end

  describe "DELETE /apps/:app_id/errs/:id/destroy_comment" do
    render_views

    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "successful comment deletion" do
      let(:problem) { Fabricate(:problem_with_comments) }
      let(:comment) { problem.reload.comments.first }

      before(:each) do
        delete :destroy_comment, :app_id => problem.app.id, :id => problem.id, :comment_id => comment.id.to_s
        problem.reload
      end

      it "should delete the comment" do
        problem.comments.detect{|c| c.id.to_s == comment.id }.should == nil
      end

      it "should redirect to problem page" do
        response.should redirect_to( app_err_path(problem.app, problem) )
      end
    end
  end

  describe "Bulk Actions" do
    before(:each) do
      sign_in Fabricate(:admin)
      @problem1 = Fabricate(:err, :problem => Fabricate(:problem, :resolved => true)).problem
      @problem2 = Fabricate(:err, :problem => Fabricate(:problem, :resolved => false)).problem
    end

    it "should apply to multiple problems" do
      post :resolve_several, :problems => [@problem1.id.to_s, @problem2.id.to_s]
      assigns(:selected_problems).should == [@problem1, @problem2]
    end

    it "should require at least one problem" do
      post :resolve_several, :problems => []
      request.flash[:notice].should match(/You have not selected any/)
    end

    context "POST /errs/merge_several" do
      it "should require at least two problems" do
        post :merge_several, :problems => [@problem1.id.to_s]
        request.flash[:notice].should match(/You must select at least two/)
      end

      it "should merge the problems" do
        lambda {
          post :merge_several, :problems => [@problem1.id.to_s, @problem2.id.to_s]
          assigns(:merged_problem).reload.errs.length.should == 2
        }.should change(Problem, :count).by(-1)
      end
    end

    context "POST /errs/unmerge_several" do
      it "should unmerge a merged problem" do
        merged_problem = Problem.merge!(@problem1, @problem2)
        merged_problem.errs.length.should == 2
        lambda {
          post :unmerge_several, :problems => [merged_problem.id.to_s]
          merged_problem.reload.errs.length.should == 1
        }.should change(Problem, :count).by(1)
      end
    end

    context "POST /errs/resolve_several" do
      it "should resolve the issue" do
        post :resolve_several, :problems => [@problem2.id.to_s]
        @problem2.reload.resolved?.should == true
      end
    end

    context "POST /errs/unresolve_several" do
      it "should unresolve the issue" do
        post :unresolve_several, :problems => [@problem1.id.to_s]
        @problem1.reload.resolved?.should == false
      end
    end

    context "POST /errs/destroy_several" do
      it "should delete the errs" do
        lambda {
          post :destroy_several, :problems => [@problem1.id.to_s]
        }.should change(Problem, :count).by(-1)
      end
    end
  end

end

