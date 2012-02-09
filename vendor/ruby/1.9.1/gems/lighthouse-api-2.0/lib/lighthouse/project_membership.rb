module Lighthouse
  class ProjectMembership < Base
    self.element_name = 'membership'
    self.site_format << "/projects/:project_id"

    def save
      raise Error, "Cannot modify memberships from the API"
    end
  end
end
