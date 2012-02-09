module Lighthouse
  class Bin < Base
    site_format << '/projects/:project_id'

    def tickets(options = {})
      Ticket.find(:all, :params => options.merge(prefix_options).update(:q => query))
    end
  end
end
