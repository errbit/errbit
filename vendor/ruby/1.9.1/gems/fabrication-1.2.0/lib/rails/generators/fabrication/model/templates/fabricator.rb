Fabricator(:<%= singular_name %>) do
<% attributes.each do |attribute| -%>
  <%= attribute.name %> <%= attribute.default.inspect %>
<% end -%>
end
