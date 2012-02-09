module Lighthouse
  class Milestone < Base
    site_format << '/projects/:project_id'

    def tickets(options = {})
      Ticket.find(:all, :params => options.merge(prefix_options).update(:q => %{milestone:"#{title}"}))
    end
  end
end
