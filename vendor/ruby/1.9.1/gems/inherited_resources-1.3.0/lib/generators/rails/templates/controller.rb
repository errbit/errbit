class <%= controller_class_name %>Controller < InheritedResources::Base
<% if options[:singleton] -%>
  defaults :singleton => true
<% end -%>
end
