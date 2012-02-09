module Lighthouse
  class TagResource < Base
    self.element_name = 'tag'
    site_format << '/projects/:project_id'

    def name
      @name ||= Tag.new(attributes['name'], prefix_options[:project_id])
    end

    def tickets(options = {})
      name.tickets(options)
    end
  end
end
