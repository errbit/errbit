require 'spec_helper'

describe ErrsController do
  
  let(:project) { Factory(:project) }
  let(:err) { Factory(:err, :project => project) }
  
  describe "GET /errs" do
    it "gets a paginated list of unresolved errors" do
      errors = WillPaginate::Collection.new(1,30)
      3.times { errors << Factory(:err) }
      Err.should_receive(:unresolved).and_return(
        mock('proxy', :ordered => mock('proxy', :paginate => errors))
      )
      get :index
      assigns(:errs).should == errors
    end
  end
  
  describe "GET /errs/:id" do
    before do
      3.times { Factory(:notice, :err => err)}
    end
    
    it "finds the project" do
      get :show, :project_id => project.id, :id => err.id
      assigns(:project).should == project
    end
    
    it "finds the err" do
      get :show, :project_id => project.id, :id => err.id
      assigns(:err).should == err
    end
    
    it "paginates the notices, 1 at a time" do
      Project.stub(:find).with(project.id).and_return(project)
      project.errs.stub(:find).with(err.id).and_return(err)
      err.notices.should_receive(:ordered).and_return(proxy = stub('proxy'))
      proxy.should_receive(:paginate).with(:page => 3, :per_page => 1).
        and_return(WillPaginate::Collection.new(1,1) << err.notices.first)
      get :show, :project_id => project.id, :id => err.id
    end
  end
  
end
