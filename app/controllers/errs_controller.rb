class ErrsController < ApplicationController
  
  def index
    @errs = Err.unresolved.ordered.paginate(:page => params[:page])
  end
  
  def show
    @project  = Project.find(params[:project_id])
    @err      = @project.errs.find(params[:id])
    @notices  = @err.notices.ordered.paginate(:page => (params[:notice] || @err.notices.count), :per_page => 1)
    @notice   = @notices.first
  end
  
end
