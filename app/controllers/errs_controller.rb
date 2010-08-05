class ErrsController < ApplicationController
  
  def index
    @errs = Err.unresolved.paginate(:page => params[:page])
  end
  
end
