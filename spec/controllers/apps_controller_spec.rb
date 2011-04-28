require 'spec_helper'

describe AppsController do
  render_views

  it_requires_authentication
  it_requires_admin_privileges :for => {:new => :get, :edit => :get, :create => :post, :update => :put, :destroy => :delete}

  describe "GET /apps" do
    context 'when logged in as an admin' do
      it 'finds all apps' do
        sign_in Factory(:admin)
        3.times { Factory(:app) }
        apps = App.all
        get :index
        assigns(:apps).should == apps
      end
    end

    context 'when logged in as a regular user' do
      it 'finds apps the user is watching' do
        sign_in(user = Factory(:user))
        unwatched_app = Factory(:app)
        watched_app1 = Factory(:app)
        watched_app2 = Factory(:app)
        Factory(:user_watcher, :user => user, :app => watched_app1)
        Factory(:user_watcher, :user => user, :app => watched_app2)
        get :index
        assigns(:apps).should include(watched_app1, watched_app2)
        assigns(:apps).should_not include(unwatched_app)
      end
    end
  end

  describe "GET /apps/:id" do
    context 'logged in as an admin' do
      before(:each) do
        @user = Factory(:admin)
        sign_in @user
        @app = Factory(:app)
        @err = Factory :err, :app => @app
        @notice = Factory :notice, :err => @err
      end

      it 'finds the app' do
        get :show, :id => @app.id
        assigns(:app).should == @app
      end

      it "should not raise errors for app with err without notices" do
        Factory :err, :app => @app
        lambda { get :show, :id => @app.id }.should_not raise_error
      end

      it "should list atom feed successfully" do
        get :show, :id => @app.id, :format => "atom"
        response.should be_success
        response.body.should match(@err.message)
      end

      context "pagination" do
        before(:each) do
          35.times { Factory :err, :app => @app }
        end

        it "should have default per_page value for user" do
          get :show, :id => @app.id
          assigns(:errs).size.should == User::PER_PAGE
        end

        it "should be able to override default per_page value" do
          @user.update_attribute :per_page, 10
          get :show, :id => @app.id
          assigns(:errs).size.should == 10
        end
      end
    end

    context 'logged in as a user' do
      it 'finds the app if the user is watching it' do
        pending
      end

      it 'does not find the app if the user is not watching it' do
        sign_in Factory(:user)
        app = Factory(:app)
        lambda {
          get :show, :id => app.id
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  context 'logged in as an admin' do
    before do
      sign_in Factory(:admin)
    end

    describe "GET /apps/new" do
      it 'instantiates a new app with a prebuilt watcher' do
        get :new
        assigns(:app).should be_a(App)
        assigns(:app).should be_new_record
        assigns(:app).watchers.should_not be_empty
      end
    end

    describe "GET /apps/:id/edit" do
      it 'finds the correct app' do
        app = Factory(:app)
        get :edit, :id => app.id
        assigns(:app).should == app
      end
    end

    describe "POST /apps" do
      before do
        @app = Factory(:app)
        App.stub(:new).and_return(@app)
      end

      context "when the create is successful" do
        before do
          @app.should_receive(:save).and_return(true)
        end

        it "should redirect to the app page" do
          post :create, :app => {}
          response.should redirect_to(app_path(@app))
        end

        it "should display a message" do
          post :create, :app => {}
          request.flash[:success].should match(/success/)
        end
      end

      context "when the create is unsuccessful" do
        it "should render the new page" do
          @app.should_receive(:save).and_return(false)
          post :create, :app => {}
          response.should render_template(:new)
        end
      end
    end

    describe "PUT /apps/:id" do
      before do
        @app = Factory(:app)
      end

      context "when the update is successful" do
        it "should redirect to the app page" do
          put :update, :id => @app.id, :app => {}
          response.should redirect_to(app_path(@app))
        end

        it "should display a message" do
          put :update, :id => @app.id, :app => {}
          request.flash[:success].should match(/success/)
        end
      end

      context "changing name" do
        it "should redirect to app page" do
          id = @app.id
          put :update, :id => id, :app => {:name => "new name"}
          response.should redirect_to(app_path(id))
        end
      end

      context "when the update is unsuccessful" do
        it "should render the edit page" do
          put :update, :id => @app.id, :app => { :name => '' }
          response.should render_template(:edit)
        end
      end

      context "setting up issue tracker", :cur => true do
        context "unknown tracker type" do
          before(:each) do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'unknown', :project_id => '1234', :api_token => '123123', :account => 'myapp'
            } }
            @app.reload
          end

          it "should not create issue tracker" do
            @app.issue_tracker.should be_nil
          end
        end

        context "lighthouseapp" do
          it "should save tracker params" do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'lighthouseapp', :project_id => '1234', :api_token => '123123', :account => 'myapp'
            } }
            @app.reload

            tracker = @app.issue_tracker
            tracker.issue_tracker_type.should == 'lighthouseapp'
            tracker.project_id.should == '1234'
            tracker.api_token.should == '123123'
            tracker.account.should == 'myapp'
          end

          it "should show validation notice when sufficient params are not present" do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'lighthouseapp', :project_id => '1234', :api_token => '123123'
            } }
            @app.reload

            @app.issue_tracker.should be_nil
            response.body.should match(/You must specify your Lighthouseapp account, api token and project id/)
          end
        end

        context "redmine" do
          it "should save tracker params" do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'redmine', :project_id => '1234', :api_token => '123123', :account => 'http://myapp.com'
            } }
            @app.reload

            tracker = @app.issue_tracker
            tracker.issue_tracker_type.should == 'redmine'
            tracker.project_id.should == '1234'
            tracker.api_token.should == '123123'
            tracker.account.should == 'http://myapp.com'
          end

          it "should show validation notice when sufficient params are not present" do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'redmine', :project_id => '1234', :api_token => '123123'
            } }
            @app.reload

            @app.issue_tracker.should be_nil
            response.body.should match(/You must specify your Redmine url, api token and project id/)
          end
        end

        context "pivotal" do
          it "should save tracker params" do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'pivotal', :project_id => '1234', :api_token => '123123' } }
            @app.reload

            tracker = @app.issue_tracker
            tracker.issue_tracker_type.should == 'pivotal'
            tracker.project_id.should == '1234'
            tracker.api_token.should == '123123'
          end

          it "should show validation notice when sufficient params are not present" do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :issue_tracker_type => 'pivotal', :project_id => '1234' } }
            @app.reload

            @app.issue_tracker.should be_nil
            response.body.should match(/You must specify your Pivotal Tracker api token and project id/)
          end
        end
      end
    end

    describe "DELETE /apps/:id" do
      before do
        @app = Factory(:app)
        App.stub(:find).with(@app.id).and_return(@app)
      end

      it "should find the app" do
        delete :destroy, :id => @app.id
        assigns(:app).should == @app
      end

      it "should destroy the app" do
        @app.should_receive(:destroy)
        delete :destroy, :id => @app.id
      end

      it "should display a message" do
        delete :destroy, :id => @app.id
        request.flash[:success].should match(/success/)
      end

      it "should redirect to the apps page" do
        delete :destroy, :id => @app.id
        response.should redirect_to(apps_path)
      end
    end
  end

end
