require_dependency 'badges/base'
require_dependency 'badges/last_error'
require_dependency 'badges/recent_errors'

class BadgesController < ApplicationController
  expose(:app)

  def index
    @badges = Badges::Base.descendants
  end

  def show
    badge_class = Badges::Base.find_badge_for_key(params[:badge_type])
    if badge_class
      @badge = badge_class.new(app)
    else
      head :not_found
    end
  end
end
