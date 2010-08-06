class ErrsController < ApplicationController
  
  def index
    @errs = Err.unresolved.paginate(:page => params[:page])
  end
  
  def show
    @project  = Project.find(params[:project_id])
    @err      = @project.errs.find(params[:id])
    @notices  = @err.notices.paginate(:page => (params[:notice] || @err.notices.count), :per_page => 1)
    @notice   = @notices.first
  end
  
end
