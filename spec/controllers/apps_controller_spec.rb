require 'spec_helper'

describe AppsController do
  
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
      it 'finds the app' do
        sign_in Factory(:admin)
        app = Factory(:app)
        get :show, :id => app.id
        assigns(:app).should == app
      end
    end
    
    context 'logged in as a user' do
      it 'finds the app if the user is watching it' do
        
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
        App.stub(:find).with(@app.id).and_return(@app)
      end
    
      context "when the update is successful" do
        before do
          @app.should_receive(:update_attributes).and_return(true)
        end
      
        it "should redirect to the app page" do
          put :update, :id => @app.id, :app => {}
          response.should redirect_to(app_path(@app))
        end
      
        it "should display a message" do
          put :update, :id => @app.id, :app => {}
          request.flash[:success].should match(/success/)
        end
      end
    
      context "when the update is unsuccessful" do
        it "should render the edit page" do
          @app.should_receive(:update_attributes).and_return(false)
          put :update, :id => @app.id, :app => {}
          response.should render_template(:edit)
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
