require 'spec_helper'

describe AppsController, :focused => true do
  
  it_requires_authentication
  it_requires_admin_privileges :for => {:new => :get, :edit => :get, :create => :post, :update => :put, :destroy => :delete}
  
  describe "GET /apps" do
    it 'finds all apps' do
      sign_in Factory(:user)
      3.times { Factory(:app) }
      apps = App.all
      get :index
      assigns(:apps).should == apps
    end
  end
  
  describe "GET /apps/:id" do
    it 'finds the app' do
      sign_in Factory(:user)
      app = Factory(:app)
      get :show, :id => app.id
      assigns(:app).should == app
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
