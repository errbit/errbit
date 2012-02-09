module Lighthouse
  class Membership < Base
    site_format << '/users/:user_id'
    def save
      raise Error, "Cannot modify memberships from the API"
    end
  end
end