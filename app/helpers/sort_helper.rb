# encoding: utf-8
module SortHelper

  def link_for_sort(name, field=nil)
    field ||= name.underscore
    current = (params_sort == field)
    order   = (current && (params_order == "asc")) ? "desc" : "asc"
    url     = request.path + "?sort=#{field}&order=#{order}"
    options = {}
    options.merge!(:class => "current #{order}") if current
    link_to(name, url, options)
  end

end
