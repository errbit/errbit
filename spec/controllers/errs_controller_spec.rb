require 'spec_helper'

describe ErrsController do
  
  it_requires_authentication :for => {
    :index => :get, :all => :get, :show => :get, :resolve => :put
  },
  :params => {:app_id => 'dummyid', :id => 'dummyid'}
  
  let(:app) { Factory(:app) }
  let(:err) { Factory(:err, :app => app) }
    
  describe "GET /errs" do
    context 'when logged in as an admin' do
      it "gets a paginated list of unresolved errs" do
        sign_in Factory(:admin)
        errs = WillPaginate::Collection.new(1,30)
        3.times { errs << Factory(:err) }
        Err.should_receive(:unresolved).and_return(
          mock('proxy', :ordered => mock('proxy', :paginate => errs))
        )
        get :index
        assigns(:errs).should == errs
      end
    end
    
    context 'when logged in as a user' do
      it 'gets a paginated list of unresolved errs for the users apps' do
        sign_in(user = Factory(:user))
        unwatched_err = Factory(:err)
        watched_unresolved_err = Factory(:err, :app => Factory(:watcher, :user => user).app, :resolved => false)
        watched_resolved_err = Factory(:err, :app => Factory(:watcher, :user => user).app, :resolved => true)
        get :index
        assigns(:errs).should include(watched_unresolved_err)
        assigns(:errs).should_not include(unwatched_err, watched_resolved_err)
      end
    end
  end
  
  describe "GET /errs/all" do
    context 'when logged in as an admin' do
      it "gets a paginated list of all errs" do
        sign_in Factory(:admin)
        errs = WillPaginate::Collection.new(1,30)
        3.times { errs << Factory(:err) }
        3.times { errs << Factory(:err, :resolved => true)}
        Err.should_receive(:ordered).and_return(
          mock('proxy', :paginate => errs)
        )
        get :all
        assigns(:errs).should == errs
      end
    end
    
    context 'when logged in as a user' do
      it 'gets a paginated list of all errs for the users apps' do
        sign_in(user = Factory(:user))
        unwatched_err = Factory(:err)
        watched_unresolved_err = Factory(:err, :app => Factory(:watcher, :user => user).app, :resolved => false)
        watched_resolved_err = Factory(:err, :app => Factory(:watcher, :user => user).app, :resolved => true)
        get :all
        assigns(:errs).should include(watched_resolved_err, watched_unresolved_err)
        assigns(:errs).should_not include(unwatched_err)
      end
    end
  end
  
  describe "GET /apps/:app_id/errs/:id" do
    before do
      3.times { Factory(:notice, :err => err)}
    end
    
    context 'when logged in as an admin' do
      before do
        sign_in Factory(:admin)
      end
    
      it "finds the app" do
        get :show, :app_id => app.id, :id => err.id
        assigns(:app).should == app
      end
    
      it "finds the err" do
        get :show, :app_id => app.id, :id => err.id
        assigns(:err).should == err
      end
    
      it "paginates the notices, 1 at a time" do
        App.stub(:find).with(app.id).and_return(app)
        app.errs.stub(:find).with(err.id).and_return(err)
        err.notices.should_receive(:ordered).and_return(proxy = stub('proxy'))
        proxy.should_receive(:paginate).with(:page => 3, :per_page => 1).
          and_return(WillPaginate::Collection.new(1,1) << err.notices.first)
        get :show, :app_id => app.id, :id => err.id
      end
    end
    
    context 'when logged in as a user' do
      before do
        sign_in(@user = Factory(:user))
        @unwatched_err = Factory(:err)
        @watched_app = Factory(:app)
        @watcher = Factory(:watcher, :user => @user, :app => @watched_app)
        @watched_err = Factory(:err, :app => @watched_app)
      end
      
      it 'finds the err if the user is watching the app' do
        get :show, :app_id => @watched_app.to_param, :id => @watched_err.id
        assigns(:err).should == @watched_err
      end
      
      it 'raises a DocumentNotFound error if the user is not watching the app' do
        lambda {
          get :show, :app_id => @unwatched_err.app_id, :id => @unwatched_err.id
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end
  
  describe "PUT /apps/:app_id/errs/:id/resolve" do
    before do
      sign_in Factory(:admin)
      
      @err = Factory(:err)
      App.stub(:find).with(@err.app.id).and_return(@err.app)
      @err.app.errs.stub(:unresolved).
        and_return(stub('proxy', :find => @err))
      @err.stub(:resolve!)
    end
    
    it 'finds the app and the err' do
      App.should_receive(:find).with(@err.app.id).and_return(@err.app)
      @err.app.errs.should_receive(:unresolved).
        and_return(mock('proxy', :find => @err))
      put :resolve, :app_id => @err.app.id, :id => @err.id
      assigns(:app).should == @err.app
      assigns(:err).should == @err
    end
    
    it "should resolve the issue" do
      @err.should_receive(:resolve!).and_return(true)
      put :resolve, :app_id => @err.app.id, :id => @err.id
    end
    
    it "should display a message" do
      put :resolve, :app_id => @err.app.id, :id => @err.id
      request.flash[:success].should match(/Great news/)
    end
    
    it "should redirect do the errs page" do
      put :resolve, :app_id => @err.app.id, :id => @err.id
      response.should redirect_to(errs_path)
    end
  end
  
end
