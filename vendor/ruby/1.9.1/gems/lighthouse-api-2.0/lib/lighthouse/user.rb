module Lighthouse
  class User < Base
    def memberships(options = {})
      Membership.find(:all, :params => {:user_id => id})
    end
  end
end
