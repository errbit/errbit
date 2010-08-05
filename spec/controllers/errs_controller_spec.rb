require 'spec_helper'

describe ErrsController do
  
  let(:project) { Factory(:project) }
  
  describe "GET /errs" do
    it "gets a paginated list of unresolved errors" do
      errors = WillPaginate::Collection.new(1,30)
      3.times { errors << Factory(:err, :project => project) }
      Err.should_receive(:unresolved).and_return(mock('proxy', :paginate => errors))
      get :index
      assigns(:errs).should == errors
    end
  end
  
end
