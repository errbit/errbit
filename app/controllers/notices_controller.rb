class NoticesController < ApplicationController
  respond_to :xml
  
  skip_before_filter :authenticate_user!, :only => :create
  
  def create
    @notice = Notice.from_xml(request.raw_post)
    respond_with @notice
  end
  
end
