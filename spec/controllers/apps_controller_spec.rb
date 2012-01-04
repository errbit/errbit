require 'spec_helper'

describe AppsController do
  render_views

  it_requires_authentication
  it_requires_admin_privileges :for => {:new => :get, :edit => :get, :create => :post, :update => :put, :destroy => :delete}


  describe "GET /apps" do
    context 'when logged in as an admin' do
      it 'finds all apps' do
        sign_in Fabricate(:admin)
        3.times { Fabricate(:app) }
        apps = App.all
        get :index
        assigns(:apps).should == apps
      end
    end

    context 'when logged in as a regular user' do
      it 'finds apps the user is watching' do
        sign_in(user = Fabricate(:user))
        unwatched_app = Fabricate(:app)
        watched_app1 = Fabricate(:app)
        watched_app2 = Fabricate(:app)
        Fabricate(:user_watcher, :user => user, :app => watched_app1)
        Fabricate(:user_watcher, :user => user, :app => watched_app2)
        get :index
        assigns(:apps).should include(watched_app1, watched_app2)
        assigns(:apps).should_not include(unwatched_app)
      end
    end
  end

  describe "GET /apps/:id" do
    context 'logged in as an admin' do
      before(:each) do
        @user = Fabricate(:admin)
        sign_in @user
        @app = Fabricate(:app)
        @problem = Fabricate(:notice, :err => Fabricate(:err, :problem => Fabricate(:problem, :app => @app))).problem
      end

      it 'finds the app' do
        get :show, :id => @app.id
        assigns(:app).should == @app
      end

      it "should not raise errors for app with err without notices" do
        Fabricate(:err, :problem => Fabricate(:problem, :app => @app))
        lambda { get :show, :id => @app.id }.should_not raise_error
      end

      it "should list atom feed successfully" do
        get :show, :id => @app.id, :format => "atom"
        response.should be_success
        response.body.should match(@problem.message)
      end

      context "pagination" do
        before(:each) do
          35.times { Fabricate(:err, :problem => Fabricate(:problem, :app => @app)) }
        end

        it "should have default per_page value for user" do
          get :show, :id => @app.id
          assigns(:problems).to_a.size.should == User::PER_PAGE
        end

        it "should be able to override default per_page value" do
          @user.update_attribute :per_page, 10
          get :show, :id => @app.id
          assigns(:problems).to_a.size.should == 10
        end
      end

      context 'with resolved errors' do
        before(:each) do
          resolved_problem = Fabricate(:problem, :app => @app)
          Fabricate(:notice, :err => Fabricate(:err, :problem => resolved_problem))
          resolved_problem.resolve!
        end

        context 'and no params' do
          it 'shows only unresolved problems' do
            get :show, :id => @app.id
            assigns(:problems).size.should == 1
          end
        end

        context 'and all_problems=true params' do
          it 'shows all errors' do
            get :show, :id => @app.id, :all_errs => true
            assigns(:problems).size.should == 2
          end
        end
      end

      context 'with environment filters' do
        before(:each) do
          environments = ['production', 'test', 'development', 'staging']
          20.times do |i|
            Fabricate(:problem, :app => @app, :environment => environments[i % environments.length])
          end
        end

        context 'no params' do
          it 'shows errs for all environments' do
            get :show, :id => @app.id
            assigns(:problems).size.should == 21
          end
        end

        context 'environment production' do
          it 'shows errs for just production' do
            get :show, :id => @app.id, :environment => 'production'
            assigns(:problems).size.should == 6
          end
        end

        context 'environment staging' do
          it 'shows errs for just staging' do
            get :show, :id => @app.id, :environment => 'staging'
            assigns(:problems).size.should == 5
          end
        end

        context 'environment development' do
          it 'shows errs for just development' do
            get :show, :id => @app.id, :environment => 'development'
            assigns(:problems).size.should == 5
          end
        end

        context 'environment test' do
          it 'shows errs for just test' do
            get :show, :id => @app.id, :environment => 'test'
            assigns(:problems).size.should == 5
          end
        end
      end
    end

    context 'logged in as a user' do
      it 'finds the app if the user is watching it' do
        user = Fabricate(:user)
        app = Fabricate(:app)
        watcher = Fabricate(:user_watcher, :app => app, :user => user)
        sign_in user
        get :show, :id => app.id
        assigns(:app).should == app
      end

      it 'does not find the app if the user is not watching it' do
        sign_in Fabricate(:user)
        app = Fabricate(:app)
        lambda {
          get :show, :id => app.id
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  context 'logged in as an admin' do
    before do
      sign_in Fabricate(:admin)
    end

    describe "GET /apps/new" do
      it 'instantiates a new app with a prebuilt watcher' do
        get :new
        assigns(:app).should be_a(App)
        assigns(:app).should be_new_record
        assigns(:app).watchers.should_not be_empty
      end

      it "should copy attributes from an existing app" do
        @app = Fabricate(:app, :name => "do not copy",
                             :github_url => "github.com/test/example")
        get :new, :copy_attributes_from => @app.id
        assigns(:app).should be_a(App)
        assigns(:app).should be_new_record
        assigns(:app).name.should be_blank
        assigns(:app).github_url.should == "github.com/test/example"
      end
    end

    describe "GET /apps/:id/edit" do
      it 'finds the correct app' do
        app = Fabricate(:app)
        get :edit, :id => app.id
        assigns(:app).should == app
      end
    end

    describe "POST /apps" do
      before do
        @app = Fabricate(:app)
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
    end

    describe "PUT /apps/:id" do
      before do
        @app = Fabricate(:app)
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

      context "changing email_at_notices" do
        it "should parse legal csv values" do
          put :update, :id => @app.id, :app => { :email_at_notices => '1,   4,      7,8,  10' }
          @app.reload
          @app.email_at_notices.should == [1, 4, 7, 8, 10]
        end
        context "failed parsing of CSV" do
          it "should set the default value" do
            @app = Fabricate(:app, :email_at_notices => [1, 2, 3, 4])
            put :update, :id => @app.id, :app => { :email_at_notices => 'asdf, -1,0,foobar,gd00,0,abc' }
            @app.reload
            @app.email_at_notices.should == Errbit::Config.email_at_notices
          end

          it "should display a message" do
            put :update, :id => @app.id, :app => { :email_at_notices => 'qwertyuiop' }
            request.flash[:error].should match(/Couldn't parse/)
          end
        end
      end

      context "setting up issue tracker", :cur => true do
        context "unknown tracker type" do
          before(:each) do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :type => 'unknown', :project_id => '1234', :api_token => '123123', :account => 'myapp'
            } }
            @app.reload
          end

          it "should not create issue tracker" do
            @app.issue_tracker_configured?.should == false
          end
        end

        IssueTracker.subclasses.each do |tracker_klass|
          context tracker_klass do
            it "should save tracker params" do
              params = tracker_klass::Fields.inject({}){|hash,f| hash[f[0]] = "test_value"; hash }
              params[:ticket_properties] = "card_type = defect" if tracker_klass == MingleTracker
              params[:type] = tracker_klass.to_s
              put :update, :id => @app.id, :app => {:issue_tracker_attributes => params}

              @app.reload

              tracker = @app.issue_tracker
              tracker.should be_a(tracker_klass)
              tracker_klass::Fields.each do |field, field_info|
                case field
                when :ticket_properties; tracker.send(field.to_sym).should == 'card_type = defect'
                else tracker.send(field.to_sym).should == 'test_value'
                end
              end
            end

            it "should show validation notice when sufficient params are not present" do
              # Leave out one required param
              params = tracker_klass::Fields[1..-1].inject({}){|hash,f| hash[f[0]] = "test_value"; hash }
              params[:type] = tracker_klass.to_s
              put :update, :id => @app.id, :app => {:issue_tracker_attributes => params}

              @app.reload
              @app.issue_tracker_configured?.should == false
              response.body.should match(/You must specify your/)
            end
          end
        end
      end
    end

    describe "DELETE /apps/:id" do
      before do
        @app = Fabricate(:app)
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

