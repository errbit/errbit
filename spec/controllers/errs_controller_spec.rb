require 'spec_helper'

describe ErrsController do
  
  let(:app) { Factory(:app) }
  let(:err) { Factory(:err, :app => app) }
  
  describe "GET /errs" do
    it "gets a paginated list of unresolved errs" do
      errs = WillPaginate::Collection.new(1,30)
      3.times { errs << Factory(:err) }
      Err.should_receive(:unresolved).and_return(
        mock('proxy', :ordered => mock('proxy', :paginate => errs))
      )
      get :index
      assigns(:errs).should == errs
    end
  end
  
  describe "GET /errs/all" do
    it "gets a paginated list of all errs" do
      errs = WillPaginate::Collection.new(1,30)
      3.times { errs << Factory(:err) }
      3.times { errs << Factory(:err, :resolved => true)}
      Err.should_receive(:ordered).and_return(
        mock('proxy', :paginate => errs)
      )
      get :index
      assigns(:errs).should == errs
    end
  end
  
  describe "GET /apps/:app_id/errs/:id" do
    before do
      3.times { Factory(:notice, :err => err)}
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
  
  describe "PUT /apps/:app_id/errs/:id/resolve" do
    before do
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
