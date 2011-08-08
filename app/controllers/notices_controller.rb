class NoticesController < ApplicationController
  respond_to :xml

  skip_before_filter :authenticate_user!, :only => :create

  def create
    # params[:data] if the notice came from a GET request, raw_post if it came via POST
    @notice = Notice.from_xml(params[:data] || request.raw_post)
    respond_with @notice
  end

end
