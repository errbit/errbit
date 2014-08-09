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

  def link_for_app_sort(name, field=nil)
    field ||= name.underscore
    current = (app_params_sort == field)
    order   = (current && (app_params_order == "asc")) ? "desc" : "asc"
    url     = request.path + "?app_sort=#{field}&app_order=#{order}"
    options = {}
    options.merge!(:class => "current #{order}") if current
    link_to(name, url, options)
  end

  def link_for_user_sort(name, field=nil)
    field ||= name.underscore
    current = (user_params_sort == field)
    order   = (current && (user_params_order == "asc")) ? "desc" : "asc"
    url     = request.path + "?user_sort=#{field}&user_order=#{order}"
    options = {}
    options.merge!(:class => "current #{order}") if current
    link_to(name, url, options)
  end
end
