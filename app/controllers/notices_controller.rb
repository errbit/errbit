class NoticesController < ApplicationController
  respond_to :xml
  
  def create
    @notice = Notice.from_xml(request.raw_post)
    respond_with @notice
  end
  
end
